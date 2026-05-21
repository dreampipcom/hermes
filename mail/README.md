# Hermes mail stack

The `./mail` stack now uses:

- **PostgreSQL** for the optional Stalwart metadata datastore when you want database-backed metadata
- **Stalwart** for SMTP / Submission / IMAP / POP3 / JMAP and the admin UI
- **Bulwark Webmail** for the browser client

Running `./init-mail.sh` renders `./mail/docker-compose.yml`, archives any legacy docker-mailserver data under `./mail/archive/`, and starts all services in the compose file: Postgres, Stalwart, and Bulwark.

## Required environment variables

Set these in `./.env.common.private` and `./.env.mail.private` (or rely on the `.public` templates for local defaults):

| Variable | Purpose |
| --- | --- |
| `HERMES_PORT_PREFIX` | Host port prefix used by the compose file (`77` => SMTP on `7712`, admin on `7719`, Bulwark on `7720`). |
| `HERMES_DNS_RESOLVER` | DNS resolver injected into both containers. |
| `HERMES_MAIL_MAIN_HOSTNAME` | Mail hostname advertised by Stalwart for SMTP / IMAP / POP3. |
| `HERMES_MAIL_DOMAINS` | Required list of hosted mailbox domains that Stalwart should serve, for example `dupip.com,dpip.cc`. |
| `HERMES_MAIL_SERVER_URL` | Public Stalwart URL used by the admin UI and by Bulwark's JMAP client. For local development the default expands to `http://localhost:${HERMES_PORT_PREFIX}19` (`http://localhost:7719` when `HERMES_PORT_PREFIX=77`). |
| `HERMES_MAIL_ADMIN_USER` | Bootstrap administrator username for the first Stalwart login. |
| `HERMES_MAIL_ADMIN_PASSWORD` | Bootstrap administrator password for the first Stalwart login. Leave it blank to let `./init-mail.sh` generate one into `./mail/docker-compose.yml` for the current run, or set it explicitly for persistent deployments. |
| `HERMES_MAIL_METADATA_BACKEND` | Planning/bootstrap helper value for the metadata backend you intend to choose in Stalwart (`rocksdb` for local-only setups, `postgres` when pairing metadata with the bundled Postgres service). `./init-mail.sh` does not apply this automatically inside Stalwart; choose it yourself during the Stalwart storage/bootstrap flow in the admin UI. |
| `HERMES_MAIL_METADATA_DB_HOST` | Hostname for the bundled Postgres metadata service inside the mail compose network. |
| `HERMES_MAIL_METADATA_DB_PORT` | Port for the bundled Postgres metadata service inside the mail compose network. |
| `HERMES_MAIL_METADATA_DB_NAME` | Database name created for Stalwart metadata. |
| `HERMES_MAIL_METADATA_DB_USER` | Database user created for Stalwart metadata. |
| `HERMES_MAIL_METADATA_DB_PASSWORD` | Database password for the bundled Postgres metadata service. Leave it blank to let `./init-mail.sh` generate one into `./mail/docker-compose.yml` for the current run, or set it explicitly for persistent deployments. |
| `HERMES_MAIL_WEBMAIL_SESSION_SECRET` | Bulwark session secret. Leave it blank to let `./init-mail.sh` generate one locally, or set it explicitly for persistent deployments. |

Optional Bulwark branding variables are also available in `./.env.mail.public`:

- `HERMES_MAIL_WEBMAIL_HOSTNAME`
- `HERMES_MAIL_WEBMAIL_APP_NAME`
- `HERMES_MAIL_WEBMAIL_SHORT_NAME`
- `HERMES_MAIL_WEBMAIL_DESCRIPTION`
- `HERMES_MAIL_WEBMAIL_COMPANY_NAME`
- `HERMES_MAIL_WEBMAIL_WEBSITE_URL`
- `HERMES_MAIL_PRIMARY_DOMAIN`
- `HERMES_MAIL_ADDITIONAL_DOMAINS`
- `HERMES_MAIL_ALIAS_DOMAINS`
- `HERMES_MAIL_METADATA_BACKEND`
- `HERMES_MAIL_METADATA_DB_HOST`
- `HERMES_MAIL_METADATA_DB_PORT`
- `HERMES_MAIL_METADATA_DB_NAME`
- `HERMES_MAIL_METADATA_DB_USER`
- `HERMES_MAIL_METADATA_DB_PASSWORD`
- `HERMES_MAIL_STORAGE_BACKEND`
- `HERMES_MAIL_S3_BUCKET`
- `HERMES_MAIL_S3_ENDPOINT`
- `HERMES_MAIL_S3_REGION`
- `HERMES_MAIL_S3_ACCESS_KEY`
- `HERMES_MAIL_S3_SECRET_KEY`
- `HERMES_MAIL_S3_PATH_STYLE`

`HERMES_MAIL_DOMAINS` is the source-of-truth list that should contain every mailbox domain you plan to host in Stalwart. `HERMES_MAIL_PRIMARY_DOMAIN` and `HERMES_MAIL_ADDITIONAL_DOMAINS` are optional helper variables for documenting how you want to split that list during bootstrap, while `HERMES_MAIL_ALIAS_DOMAINS` is only for domains that should forward into another hosted domain instead of owning separate mailboxes.

## Local bootstrap

1. Run `./init-mail.sh`
2. Open `http://localhost:7719/admin` (or replace `77` with your `HERMES_PORT_PREFIX`)
3. Sign in with `HERMES_MAIL_ADMIN_USER` / `HERMES_MAIL_ADMIN_PASSWORD`
4. Complete the Stalwart bootstrap flow, then create your domains and mailboxes
5. Open Bulwark at `http://localhost:7720` (or replace `77` with your `HERMES_PORT_PREFIX`)

## Multiple domains and aliases

Stalwart can serve multiple mailbox domains while still using a single mail hostname.

Example:

- `HERMES_MAIL_MAIN_HOSTNAME=mail.dupip.com`
- `HERMES_MAIL_DOMAINS=dupip.com,dpip.cc`
- `HERMES_MAIL_PRIMARY_DOMAIN=dupip.com`
- `HERMES_MAIL_ADDITIONAL_DOMAINS=dpip.cc`

That gives you:

- SMTP / IMAP / POP3 / webmail endpoint: `mail.dupip.com`
- main addresses like `dude@dupip.com`
- second hosted-domain addresses like `bob@dpip.cc`

After the initial Stalwart login:

1. Add `dupip.com` and `dpip.cc` as local domains in Stalwart.
2. Create mailboxes on whichever domain should own the account.
3. If `bob@dpip.cc` should be a different mailbox from `bob@dupip.com`, create it as its own account on `dpip.cc`.
4. If `bob@dpip.cc` should deliver into `bob@dupip.com`, configure either:
   - a **domain alias** from `dpip.cc` to `dupip.com`, or
   - an **address alias** from `bob@dpip.cc` to `bob@dupip.com`.

Use `HERMES_MAIL_ALIAS_DOMAINS` to keep track of any alias-only domains you intend to configure in Stalwart.

## S3-backed storage

The Compose stack now includes a bundled `hermes-mail-postgres` container so Stalwart can keep metadata in Postgres while storing message blobs in S3-compatible object storage.

The local persistent paths are:

- `./mail/data/postgres`
- `./mail/data/stalwart/etc`
- `./mail/data/stalwart/data`

If you want Stalwart to store mail/blob data in AWS S3 or an S3-compatible backend such as MinIO, keep the config volume mounted and use the bundled Postgres service for metadata during the Stalwart bootstrap flow.

Suggested private env values:

```bash
HERMES_MAIL_METADATA_BACKEND=postgres
HERMES_MAIL_METADATA_DB_HOST=hermes-mail-postgres
HERMES_MAIL_METADATA_DB_PORT=5432
HERMES_MAIL_METADATA_DB_NAME=stalwart
HERMES_MAIL_METADATA_DB_USER=stalwart
HERMES_MAIL_METADATA_DB_PASSWORD=...
HERMES_MAIL_STORAGE_BACKEND=s3
HERMES_MAIL_S3_BUCKET=hermes-mail
HERMES_MAIL_S3_ENDPOINT=https://s3.example.org
HERMES_MAIL_S3_REGION=eu-west-1
HERMES_MAIL_S3_ACCESS_KEY=...
HERMES_MAIL_S3_SECRET_KEY=...
HERMES_MAIL_S3_PATH_STYLE=true
```

During bootstrap:

1. choose Postgres for Stalwart's metadata/data store
2. point it at `hermes-mail-postgres:5432`
3. use `HERMES_MAIL_METADATA_DB_NAME`, `HERMES_MAIL_METADATA_DB_USER`, and `HERMES_MAIL_METADATA_DB_PASSWORD`
4. configure the blob/object store with the S3 values above

For AWS S3 you can usually leave `HERMES_MAIL_S3_ENDPOINT` empty. For MinIO/Ceph/other S3-compatible stores, set the endpoint explicitly and keep path-style access enabled when required by the provider.

For small local-only setups you can keep `HERMES_MAIL_METADATA_BACKEND=rocksdb` and `HERMES_MAIL_STORAGE_BACKEND=local`, but for external S3 storage the recommended pairing is Postgres metadata + S3 blobs.

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

The smoke test checks that the Postgres, Stalwart, and Bulwark containers are running, the Stalwart admin endpoint answers over HTTP, the Bulwark login page answers over HTTP, and the SMTP / IMAP / POP3 ports accept TCP connections.
