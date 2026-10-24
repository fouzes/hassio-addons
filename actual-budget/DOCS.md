# Actual Budget add-on

## Installation

1. Add this repository to the Home Assistant add-on store.
2. Install the **Actual Budget** add-on.
3. Review the configuration, then start the add-on.
4. Open **Actual Budget** from the sidebar (turn on **Show in sidebar** on the
   add-on page if it is not there) and set a password on the first visit.

## Configuration

| Option | Description |
| --- | --- |
| `ssl` | Serve Actual Budget over HTTPS. Default `false`. |
| `certfile` | Certificate file in the Home Assistant `/ssl` folder. Default `fullchain.pem`. |
| `keyfile` | Private key file in the `/ssl` folder. Default `privkey.pem`. |

## Sidebar and the add-on port

Actual Budget appears in the Home Assistant sidebar (ingress) and can also be
opened directly on port `5006`.

Actual Budget cannot be served from a URL sub-path, which is what ingress
requires, so the add-on patches Actual's web client when the image is built and
puts an nginx proxy in front of it for the sidebar. Inside the sidebar:

- It works over plain HTTP; the `ssl` option is not needed.
- The budget should only be open in one browser tab at a time. Actual cannot
  coordinate several tabs inside the sidebar, so a second tab can make the first
  one stop saving.
- Actual's offline mode (service worker) is switched off, so Actual needs Home
  Assistant to be reachable.

The sidebar entry and port `5006` are separate: your budget files are the same,
but each browser keeps its own local copy and sign-in for each address. You can
change or disable the host port on the add-on's **Network** tab.

## HTTPS on the add-on port

When you open Actual Budget on port `5006` instead of the sidebar, it only works
in a secure context. Over plain `http://` it works from the Home Assistant host
itself (`localhost`), but from any other device the browser blocks required
features and Actual shows an error.

Either enable `ssl` and make sure the certificate matches the host name you
use to open it (for example `https://homeassistant.local:5006` or your own
domain), or put a reverse proxy that provides HTTPS in front of port `5006`.

If `ssl` is enabled and a file is missing from `/ssl`, the add-on stops with an
error in its log.

## Signing in

Actual Budget has its own password. It is set on the first visit and is not
linked to Home Assistant users. The sidebar is available to every Home
Assistant user who can open the add-on. Anyone who can reach port `5006` can see
the login page, so do not expose the port to the internet without HTTPS.

## Data and backups

Budget files and the server database are stored in the add-on's data directory
and are included in Home Assistant backups. Backups stop the add-on briefly so
the files are consistent.

## Support

Actual Budget documentation: <https://actualbudget.org/docs/>
