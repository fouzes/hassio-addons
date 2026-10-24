# Changelog

This add-on follows its own [semantic versioning](https://semver.org/),
independent of the Actual Budget version it bundles.

## 0.2.0

- Add a sidebar entry through Home Assistant ingress. Actual Budget has no
  base-path setting, so the web client is patched at image build time to resolve
  its addresses against the page's `<base>` tag, and an nginx proxy on the
  ingress port writes the ingress path into it. The build fails if an Actual
  update changes the code the patch is written for.
- Opening Actual Budget from the sidebar works over plain HTTP; it does not need
  the `ssl` option. The service worker (offline use) is disabled, and the budget
  should only be open in one browser tab at a time inside the sidebar.
- The add-on port (`5006`) and the `ssl` option keep working as before.

## 0.1.3

- Fix start-up: the upstream image now ships `app.js` instead of
  `build/app.js`, so the server could not be found.
- Allow memory-mapping libraries and native modules in the AppArmor profile.

## 0.1.2

- Add an icon, a logo and an AppArmor profile.
- Add a container health check so Home Assistant sees when the web server stops
  responding.
- Stop the add-on while a backup is taken so the budget files are consistent.

## 0.1.1

- Publish prebuilt images to GHCR so the add-on is pulled instead of built on
  the device.

## 0.1.0

- Initial release of the Actual Budget add-on.
- Bundles Actual Budget 26.10.0.
