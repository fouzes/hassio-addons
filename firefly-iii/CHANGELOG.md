# Changelog

This add-on follows its own [semantic versioning](https://semver.org/),
independent of the Firefly III version it bundles.

## 0.1.8

- Fix "refused to connect" in the sidebar panel by disabling Firefly III's `X-Frame-Options: deny` header.

## 0.1.7

- Fix `addon-log.fifo: Permission denied` by creating the log FIFO in `/run`, root-owned and world-writable.

## 0.1.6

- Route container output through a FIFO owned by `www-data` so PHP-FPM can open its log (the 0.1.5 `chown` approach did not fix it).

## 0.1.5

- Fix PHP-FPM failing with `failed to open error_log (/proc/self/fd/2): Permission denied`.

## 0.1.4

- Add Home Assistant ingress so Firefly III appears in the sidebar menu.
- Fix start-up failure `rm: cannot remove '/var/www/html/storage/upload': Device or resource busy`.
- Start through the upstream `/init` (nginx + PHP-FPM) instead of a non-existent Apache command.

## 0.1.2

- Install from a prebuilt image on GitHub Container Registry instead of building on the device.

## 0.1.1

- Fix image build failing with `apt-get ... Permission denied` by building as root.

## 0.1.0

- Initial release of the Firefly III add-on.
- Bundles Firefly III 6.2.21.
