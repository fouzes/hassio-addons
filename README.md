# Home Assistant Add-ons

A collection of add-ons for [Home Assistant](https://www.home-assistant.io/).

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**.
2. Open the menu (⋮) and choose **Repositories**.
3. Add the URL of this repository and click **Add**.
4. The add-ons below appear in the store.

## Add-ons

| Add-on | Description |
| --- | --- |
| [Actual Budget](actual-budget/README.md) | Local-first personal finance and budgeting app. |
| [Firefly III](firefly-iii/README.md) | Self-hosted personal finance manager. |

## Versioning

Every add-on has its own [semantic version](https://semver.org/) (`MAJOR.MINOR.PATCH`) in its
`config.yaml`, independent of the upstream application version it bundles.

- **MAJOR**: breaking changes to options or data layout.
- **MINOR**: new features or an upstream version update.
- **PATCH**: fixes and documentation-only changes.

The bundled upstream version is set by the version `ARG` at the top of the add-on's
`Dockerfile` (`FIREFLY_VERSION` for Firefly III, `ACTUAL_VERSION` for Actual Budget)
and is listed in its `CHANGELOG.md`. Bump the add-on version on every change that
should reach users.

## Contributing

Each add-on lives in its own directory containing `config.yaml`, a
`Dockerfile`, `README.md`, `DOCS.md`, `CHANGELOG.md`, `icon.png`, `logo.png` and
`apparmor.txt`. Pull requests that add new add-ons or improve existing ones are
welcome.

## License

Released under the [MIT License](LICENSE).
