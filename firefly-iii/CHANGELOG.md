# Changelog

This add-on follows its own [semantic versioning](https://semver.org/),
independent of the Firefly III version it bundles.

## 0.1.3

- Add Home Assistant ingress so Firefly III appears in the sidebar menu.
- Fix start-up failure `rm: cannot remove '/var/www/html/storage/upload': Device or resource busy`.

## 0.1.2

- Install from a prebuilt image on GitHub Container Registry instead of building on the device.

## 0.1.1

- Fix image build failing with `apt-get ... Permission denied` by building as root.

## 0.1.0

- Initial release of the Firefly III add-on.
- Bundles Firefly III 6.2.21.
