# Hermes mail stack

The `./mail` stack now uses:

- **Stalwart** for SMTP / Submission / IMAP / POP3 / JMAP and the admin UI
- **Bulwark Webmail** for the browser client

Running `./init-mail.sh` renders `./mail/docker-compose.yml`, archives any legacy docker-mailserver data under `./mail/archive/`, and starts both containers.

## Required environment variables

Set these in `./.env.common.private` and `./.env.mail.private` (or rely on the `.public` templates for local defaults):

| Variable | Purpose |
| --- | --- |
| `HERMES_PORT_PREFIX` | Host port prefix used by the compose file (`77` => SMTP on `7712`, admin on `7719`, Bulwark on `7720`). |
| `HERMES_DNS_RESOLVER` | DNS resolver injected into both containers. |
| `HERMES_MAIL_MAIN_HOSTNAME` | Mail hostname advertised by Stalwart for SMTP / IMAP / POP3. |
| `HERMES_MAIL_SERVER_URL` | Public Stalwart URL used by the admin UI and by Bulwark's JMAP client. For local development the default expands to `http://localhost:${HERMES_PORT_PREFIX}19` (`http://localhost:7719` when `HERMES_PORT_PREFIX=77`). |
| `HERMES_MAIL_ADMIN_USER` | Bootstrap administrator username for the first Stalwart login. |
| `HERMES_MAIL_ADMIN_PASSWORD` | Bootstrap administrator password for the first Stalwart login. Leave it blank to let `./init-mail.sh` generate one into `./mail/docker-compose.yml` for the current run, or set it explicitly for persistent deployments. |
| `HERMES_MAIL_WEBMAIL_SESSION_SECRET` | Bulwark session secret. Leave it blank to let `./init-mail.sh` generate one locally, or set it explicitly for persistent deployments. |

Optional Bulwark branding variables are also available in `./.env.mail.public`:

- `HERMES_MAIL_WEBMAIL_HOSTNAME`
- `HERMES_MAIL_WEBMAIL_APP_NAME`
- `HERMES_MAIL_WEBMAIL_SHORT_NAME`
- `HERMES_MAIL_WEBMAIL_DESCRIPTION`
- `HERMES_MAIL_WEBMAIL_COMPANY_NAME`
- `HERMES_MAIL_WEBMAIL_WEBSITE_URL`

## Local bootstrap

1. Run `./init-mail.sh`
2. Open `http://localhost:7719/admin` (or replace `77` with your `HERMES_PORT_PREFIX`)
3. Sign in with `HERMES_MAIL_ADMIN_USER` / `HERMES_MAIL_ADMIN_PASSWORD`
4. Complete the Stalwart bootstrap flow, then create your domains and mailboxes
5. Open Bulwark at `http://localhost:7720` (or replace `77` with your `HERMES_PORT_PREFIX`)

## Exposed ports

| Service | Container port | Host port |
| --- | --- | --- |
| SMTP | `25` | `${HERMES_PORT_PREFIX}12` |
| Submission | `587` | `${HERMES_PORT_PREFIX}13` |
| SMTPS | `465` | `${HERMES_PORT_PREFIX}14` |
| IMAP | `143` | `${HERMES_PORT_PREFIX}15` |
| IMAPS | `993` | `${HERMES_PORT_PREFIX}16` |
| POP3 | `110` | `${HERMES_PORT_PREFIX}17` |
| POP3S | `995` | `${HERMES_PORT_PREFIX}18` |
| Stalwart admin / JMAP | `8080` | `${HERMES_PORT_PREFIX}19` |
| Bulwark webmail | `3000` | `${HERMES_PORT_PREFIX}20` |

## Smoke test

After the stack is up, run:

```bash
./mail/smoke-test.sh
```

The smoke test checks that the two containers are running, the Stalwart admin endpoint answers over HTTP, the Bulwark login page answers over HTTP, and the SMTP / IMAP / POP3 ports accept TCP connections.
