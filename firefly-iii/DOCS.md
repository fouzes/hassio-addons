# Firefly III add-on

## Installation

1. Add this repository to the Home Assistant add-on store.
2. Install the **Firefly III** add-on.
3. Review the configuration, then start the add-on.
4. Open Firefly III from the sidebar and register the first user.

## Configuration

| Option | Description |
| --- | --- |
| `site_owner` | Contact e-mail address of the site owner. |
| `timezone` | IANA time zone, e.g. `Europe/Amsterdam`. |
| `default_language` | Default locale, e.g. `en_US`. |
| `trusted_proxies` | Comma-separated proxy IPs, or `**` to trust all. Required behind a reverse proxy. |
| `app_key` | Optional 32-character application key (or `base64:...`). If empty, a key is generated once and stored in the add-on data. |
| `auth_mode` | `builtin` (default): Firefly III's own login page. `ha_user`: sign in automatically as your Home Assistant user, see below. |
| `log_level` | One of `debug`, `info`, `notice`, `warning`, `error`, `critical`. |
| `database.type` | `sqlite` (default) or `mysql`. |
| `database.host`, `.port`, `.name`, `.username`, `.password` | Connection settings, used only when `type` is `mysql`. |

### Direct access on port 8080

The port is not published by default, so Firefly III is reachable only through
Home Assistant (ingress). To also use it directly, set a host port for
`8080/tcp` on the add-on's Network tab. Mobile apps and the Data Importer need
this. With `auth_mode: ha_user` direct connections are refused even if the port
is published.

### Signing in with your Home Assistant user

With `auth_mode: ha_user` Firefly III trusts the user that Home Assistant
passes through ingress, so there is no login page. The Home Assistant user name
becomes the Firefly III account `<name>@homeassistant.local`, created on first
visit; the first account created becomes the owner.

- Open Firefly III from the sidebar. Direct connections to port 8080 are
  refused in this mode, because otherwise anyone on your network could forge
  the user header. Clients that talk to the port directly (mobile apps, the
  Data Importer) will not work.
- Every Home Assistant user who can open the ingress URL gets their own Firefly
  III account with separate data. `panel_admin` only hides the sidebar entry
  from non-admins, it does not block the URL.
- An account you already created with a different e-mail address is not
  reused. Create it as `<ha-user>@homeassistant.local` or start fresh.

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
