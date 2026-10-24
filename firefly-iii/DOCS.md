# Firefly III add-on

## Installation

1. Add this repository to the Home Assistant add-on store.
2. Install the **Firefly III** add-on.
3. Review the configuration, then start the add-on.
4. Open Firefly III from the sidebar and register the first user.

## Configuration

| Option | Description |
| --- | --- |
| `timezone` | IANA time zone, e.g. `Europe/Amsterdam`. |
| `default_language` | Default locale, e.g. `en_US`. |
| `app_key` | Optional 32-character application key (or `base64:...`). If empty, a key is generated once and stored in the add-on data. |
| `log_level` | One of `debug`, `info`, `notice`, `warning`, `error`, `critical`. |

## Signing in

There is no Firefly III login page. The add-on trusts the user that Home
Assistant passes through ingress: the Home Assistant user name becomes the
Firefly III account `<name>@homeassistant.local`, created on first visit. The
first account created becomes the owner.

- Firefly III is only reachable through the Home Assistant sidebar. Direct
  connections to the container are refused, because otherwise anyone on your
  network could forge the user header. Clients that connect directly (mobile
  apps, the Data Importer) will not work.
- Every Home Assistant user who can open the ingress URL gets their own Firefly
  III account with separate data. `panel_admin` only hides the sidebar entry
  from non-admins, it does not block the URL.
- An account you created earlier with a different e-mail address is not
  reused. Create it as `<ha-user>@homeassistant.local` or start fresh.

The database is the built-in SQLite database, stored in the add-on data.

## Data and backups

All data (database, uploads, logs, application key) is stored in the add-on's
data directory and is included in Home Assistant backups. Backups stop the
add-on briefly so the database is consistent.

> **Keep the application key safe.** It encrypts sensitive values. If you set
> `app_key` manually, do not change it later or existing data becomes unreadable.

## Support

Firefly III documentation: <https://docs.firefly-iii.org/>
