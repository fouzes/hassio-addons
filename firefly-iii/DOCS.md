# Firefly III add-on

## Installation

1. Add this repository to the Home Assistant add-on store.
2. Install the **Firefly III** add-on.
3. Review the configuration, then start the add-on.
4. Open Firefly III from the sidebar (or `http://<home-assistant-host>:8080`) and register the first user.

## Configuration

| Option | Description |
| --- | --- |
| `site_owner` | Contact e-mail address of the site owner. |
| `timezone` | IANA time zone, e.g. `Europe/Amsterdam`. |
| `default_language` | Default locale, e.g. `en_US`. |
| `trusted_proxies` | Comma-separated proxy IPs, or `**` to trust all. Required behind a reverse proxy. |
| `app_key` | Optional 32-character application key (or `base64:...`). If empty, a key is generated once and stored in the add-on data. |
| `log_level` | One of `debug`, `info`, `notice`, `warning`, `error`, `critical`. |
| `database.type` | `sqlite` (default) or `mysql`. |
| `database.host`, `.port`, `.name`, `.username`, `.password` | Connection settings, used only when `type` is `mysql`. |

### Using MariaDB

Install the official MariaDB add-on, create a database and user for Firefly III,
then set `database.type` to `mysql` and fill in the connection settings.

## Data and backups

All data (database, uploads, logs, application key) is stored in the add-on's
data directory and is included in Home Assistant backups.

> **Keep the application key safe.** It encrypts sensitive values. If you set
> `app_key` manually, do not change it later or existing data becomes unreadable.

## Support

Firefly III documentation: <https://docs.firefly-iii.org/>
