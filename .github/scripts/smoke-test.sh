#!/bin/bash
# Start an add-on image the way the Home Assistant Supervisor does and fail
# unless it keeps running and answers on its web port.
#
# Usage: smoke-test.sh <addon-dir> <image> [timeout-seconds]
#
# What is reproduced from the Supervisor:
#   - /data with options.json built from the `options:` defaults in config.yaml
#   - the folders listed under `map:` (addon_config, ssl, ...)
#   - the add-on's apparmor.txt, loaded into the kernel and applied to the
#     container (the profile must be named after the slug)
#   - the hassio network (172.30.32.0/23), with the ingress proxy at
#     172.30.32.2, so access restrictions based on that address work
#
# Needs: docker, python3 with PyYAML, sudo, and AppArmor in the kernel plus
# apparmor_parser when the add-on ships an apparmor.txt.
set -euo pipefail

ADDON=${1:?add-on directory}
IMAGE=${2:?image to test}
TIMEOUT=${3:-240}

CONFIG="$ADDON/config.yaml"
NAME="smoke-$(basename "$ADDON")"
NETWORK=hassio-smoke
ADDON_IP=172.30.32.3
PROXY_IP=172.30.32.2
CURL_IMAGE=curlimages/curl:8.11.1

# Print one value from config.yaml: a scalar, or the items/keys of a list/map
# one per line.
config() {
    python3 - "$CONFIG" "$1" <<'EOF'
import sys, yaml
value = yaml.safe_load(open(sys.argv[1])).get(sys.argv[2])
if isinstance(value, (list, dict)):
    print(*value, sep="\n")
elif value is not None:
    print(value)
EOF
}

SLUG=$(config slug)
INGRESS=$(config ingress)
INGRESS_PORT=$(config ingress_port)
if [ "$INGRESS" = "True" ]; then
    PORT=${INGRESS_PORT:-8099}  # the Supervisor's default ingress port
else
    PORT=$(config ports | head -n1 | cut -d/ -f1)
fi
if [ -z "$SLUG" ] || [ -z "$PORT" ]; then
    echo "::error::$CONFIG has no slug or web port"
    exit 1
fi

WORK=$(mktemp -d)
PROFILE_LOADED=
cleanup() {
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    docker network rm "$NETWORK" >/dev/null 2>&1 || true
    if [ -n "$PROFILE_LOADED" ]; then
        sudo apparmor_parser -R "$ADDON/apparmor.txt" >/dev/null 2>&1 || true
    fi
    sudo rm -rf "$WORK"
}
trap cleanup EXIT

diagnose() {
    echo "::group::Container state"
    docker inspect --format '{{json .State}}' "$NAME" 2>&1 || true
    echo "::endgroup::"
    echo "::group::Container logs"
    docker logs "$NAME" 2>&1 | tail -n 200 || true
    echo "::endgroup::"
    echo "::group::AppArmor denials"
    sudo dmesg 2>/dev/null | grep -i 'apparmor="DENIED"' | tail -n 50 || echo "none found"
    echo "::endgroup::"
}
fail() {
    echo "::error::$ADDON: $*"
    diagnose
    exit 1
}

# --- Supervisor-like environment ----------------------------------------
mkdir -p "$WORK/data"
python3 - "$CONFIG" "$WORK/data/options.json" <<'EOF'
import json, sys, yaml
options = yaml.safe_load(open(sys.argv[1])).get("options") or {}
json.dump(options, open(sys.argv[2], "w"))
EOF

volumes=(-v "$WORK/data:/data")
while read -r entry; do
    [ -n "$entry" ] || continue
    kind=${entry%%:*}
    mode=${entry#*:}
    [ "$mode" != "$entry" ] || mode=ro
    case "$kind" in
        addon_config | config) target=/config ;;
        homeassistant_config) target=/homeassistant ;;
        all_addon_configs) target=/addon_configs ;;
        ssl | share | media | backup | addons) target=/$kind ;;
        *)
            echo "::error::$CONFIG maps unknown folder $kind"
            exit 1
            ;;
    esac
    mkdir -p "$WORK/$kind"
    volumes+=(-v "$WORK/$kind:$target:$mode")
done < <(config map)

security=()
if [ -f "$ADDON/apparmor.txt" ]; then
    if ! grep -Eq "^profile +$SLUG[ {]" "$ADDON/apparmor.txt"; then
        echo "::error::$ADDON/apparmor.txt must define a profile named $SLUG"
        exit 1
    fi
    if [ ! -d /sys/kernel/security/apparmor ]; then
        echo "::error::AppArmor is not enabled on this runner"
        exit 1
    fi
    sudo apparmor_parser -r -W "$ADDON/apparmor.txt"
    PROFILE_LOADED=1
    security=(--security-opt "apparmor=$SLUG")
fi

docker network rm "$NETWORK" >/dev/null 2>&1 || true
docker network create --subnet 172.30.32.0/23 --gateway 172.30.32.1 "$NETWORK" >/dev/null
docker pull -q "$CURL_IMAGE" >/dev/null

# --- Start and probe ----------------------------------------------------
docker run -d --name "$NAME" --network "$NETWORK" --ip "$ADDON_IP" \
    "${volumes[@]}" "${security[@]}" -e SUPERVISOR_TOKEN=smoke-test "$IMAGE" >/dev/null

# Fetch the web root as the ingress proxy would and print the HTTP status.
probe() {
    docker run --rm --network "$NETWORK" --ip "$PROXY_IP" "$CURL_IMAGE" \
        -s -o /dev/null -w '%{http_code}' --max-time 10 \
        -H 'X-Remote-User-Name: smoke-test' "http://$ADDON_IP:$PORT/" 2>/dev/null || true
}
running() { [ "$(docker inspect --format '{{.State.Running}}' "$NAME")" = true ]; }

start=$SECONDS
status=000
until [[ "$status" =~ ^[23][0-9][0-9]$ ]]; do
    running || fail "container exited during start-up"
    [ $((SECONDS - start)) -lt "$TIMEOUT" ] \
        || fail "port $PORT did not return a 2xx/3xx response within ${TIMEOUT}s (last status $status)"
    sleep 3
    status=$(probe)
done
echo "$ADDON answered HTTP $status on port $PORT after $((SECONDS - start))s"

# The add-on must stay up and keep answering, not just respond once.
sleep 15
running || fail "container exited after start-up"
status=$(probe)
[[ "$status" =~ ^[23][0-9][0-9]$ ]] || fail "port $PORT stopped answering (status $status)"

# The image's HEALTHCHECK is what the Supervisor watches; make sure it passes.
mapfile -t health < <(docker inspect --format '{{json .Config.Healthcheck.Test}}' "$NAME" | python3 -c '
import json, sys
test = json.load(sys.stdin) or []
print(*(test[1:] if test[:1] == ["CMD"] else []), sep="\n")')
if [ "${#health[@]}" -gt 0 ]; then
    docker exec "$NAME" "${health[@]}" || fail "HEALTHCHECK command failed"
fi

echo "$ADDON: smoke test passed"
