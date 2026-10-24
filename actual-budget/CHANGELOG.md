# Changelog

This add-on follows its own [semantic versioning](https://semver.org/),
independent of the Actual Budget version it bundles.

## 0.1.2

- Add an icon, a logo and an AppArmor profile.
- Add a watchdog so Home Assistant restarts the add-on if the web server stops
  responding.
- Stop the add-on while a backup is taken so the budget files are consistent.

## 0.1.1

- Publish prebuilt images to GHCR so the add-on is pulled instead of built on
  the device.

## 0.1.0

- Initial release of the Actual Budget add-on.
- Bundles Actual Budget 26.10.0.
