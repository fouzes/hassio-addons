# Actual Budget add-on

## Installation

1. Add this repository to the Home Assistant add-on store.
2. Install the **Actual Budget** add-on.
3. Review the configuration, then start the add-on.
4. Click **Open web UI** and set a password on the first visit.

## Configuration

| Option | Description |
| --- | --- |
| `ssl` | Serve Actual Budget over HTTPS. Default `false`. |
| `certfile` | Certificate file in the Home Assistant `/ssl` folder. Default `fullchain.pem`. |
| `keyfile` | Private key file in the `/ssl` folder. Default `privkey.pem`. |

## Why there is no sidebar entry

Actual Budget cannot be served from a URL sub-path, which is what Home Assistant
ingress requires, so the add-on listens on its own port (`5006`) instead. You
can change the host port on the add-on's **Network** tab.

## HTTPS

Actual Budget only works in a secure context. Opening it over plain `http://`
works from the Home Assistant host itself (`localhost`), but from any other
device the browser blocks required features and Actual shows an error.

Either enable `ssl` and make sure the certificate matches the host name you
use to open it (for example `https://homeassistant.local:5006` or your own
domain), or put a reverse proxy that provides HTTPS in front of port `5006`.

If `ssl` is enabled and a file is missing from `/ssl`, the add-on stops with an
error in its log.

## Signing in

Actual Budget has its own password. It is set on the first visit and is not
linked to Home Assistant users. Anyone who can reach port `5006` can see the
login page, so do not expose the port to the internet without HTTPS.

## Data and backups

Budget files and the server database are stored in the add-on's data directory
and are included in Home Assistant backups. Backups stop the add-on briefly so
the files are consistent.

## Support

Actual Budget documentation: <https://actualbudget.org/docs/>
