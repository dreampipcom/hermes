# Hermes - DreamPip's Messaging Platform

What: socket.io, Notion, OpenAI, Whatsapp/Telegram/etc APIs

## Getting Started

### Mail + Nextcloud deployment (Docker Compose now, k3s via `kompose`)

1. Copy each `*.public` file to its matching `*.private` file and fill in the required values.
2. Run the deployment in order from the repository root:

```bash
cp .env.common.public .env.common.private
cp .env.mail.public .env.mail.private
cp .env.cloud.public .env.cloud.private
cp .env.ingress.public .env.ingress.private
cp .env.model.public .env.model.private

./init-networks.sh
./init-weagle.sh
./init-model.sh
./init-mail.sh            # local mail storage
./init-cloud.sh
```

Use `./init-mail.sh setup:storage` only when the mail S3 variables are set and `s3fs` is installed. For a single-command bring-up, run `./init.sh`.

For k3s generation, run `./init-k8s-config.sh` after the same private env files are present. The generated manifests depend on the compose service ports, so the mail template now exports SMTP/Submission/IMAP/IMAPS/POP3/POP3S/Sieve explicitly for Traefik and `kompose`.

### MUST-NOT-BE-EMPTY variables

#### Common (`.env.common.private`)

| Variable | Why it is required |
| --- | --- |
| `HERMES_APEX` | Base mail domain for certificates and mailserver identity. |
| `HERMES_HOSTNAME` | Public FQDN used by Traefik and Nextcloud. |
| `HERMES_CERT_FILE` | Mounted TLS certificate filename. |
| `HERMES_CERT_KEY_FILE` | Mounted TLS private key filename. |
| `HERMES_MAIL_DOMAINS` | Domains provisioned in docker-mailserver. |
| `HERMES_MAIL_MAIN_HOSTNAME` | Mail host used for mailbox creation and DNS guidance. |
| `HERMES_DNS_RESOLVER` | Resolver injected into mail/cloud containers. |
| `HERMES_INGRESS_SUBNET` | Trusted proxy subnet for Nextcloud behind Traefik. |
| `HERMES_CLOUD_DB_HOST` | MariaDB host for Nextcloud. |
| `HERMES_PORT_PREFIX` | Prefix used when compose is converted into k8s services. |

#### Mail (`.env.mail.private`)

| Variable | Why it is required |
| --- | --- |
| `HERMES_MAIL_CERT_TYPE` | `docker-mailserver` TLS mode (`manual` for the bundled cert mount). |
| `HERMES_MAIN_MAILBOX` | Main administrator mailbox reference. |
| `HERMES_MAIL_INITIAL_BOXES` | Comma-separated local parts for optional bootstrap mailboxes. |
| `HERMES_MAIL_INITIAL_BOXES_DEFAULT_PASSWORD` | Password used when `setup:mailboxes` is invoked. |

Optional only when using S3-backed mail storage: `HERMES_MAIL_S3_BUCKET`, `HERMES_MAIL_S3_HOST`, `HERMES_MAIL_S3_KEY`, `HERMES_MAIL_S3_SECRET`.

#### Cloud (`.env.cloud.private`)

| Variable | Why it is required |
| --- | --- |
| `HERMES_CLOUD_BASEPATH` | Nextcloud path prefix (default `/cloud`). |
| `HERMES_CLOUD_DB_NAME` | Nextcloud MariaDB database name. |
| `HERMES_CLOUD_DB_USER` | Nextcloud MariaDB user. |
| `HERMES_CLOUD_DB_PASS` | Nextcloud MariaDB password. |
| `HERMES_CLOUD_DB_REDIS` | Redis hostname reachable on `hermes-net-model-cloud`. |

Optional S3/object-store values: `HERMES_CLOUD_S3_BUCKET`, `HERMES_CLOUD_S3_HOST`, `HERMES_CLOUD_S3_REGION`, `HERMES_CLOUD_S3_KEY`, `HERMES_CLOUD_S3_SECRET`.

#### Ingress (`.env.ingress.private`)

| Variable | Why it is required |
| --- | --- |
| `HERMES_TRAEFIK_BASE_AUTH` | Protects the Traefik dashboard. |
| `HERMES_CLOUDFLARE_EMAIL` | ACME DNS challenge account. |
| `HERMES_CLOUDFLARE_API_KEY` | ACME DNS challenge credential. |

#### Model (`.env.model.private`)

| Variable | Why it is required |
| --- | --- |
| `HERMES_MODEL_CLOUD_MARIA_IP` | Static IP assigned to `hermes-model-mariadb` on `hermes-net-model-cloud`. |

### Fresh-server notes

- `./init-mail.sh` is idempotent for local storage and only mounts S3 when `setup:storage` is requested.
- `./init-cloud.sh` now writes `cloud/data/cloud/config/hermes.config.php` from `cloud/_config.php`, so fresh installs no longer depend on an already-existing Nextcloud `config.php`.
- The mail Traefik TCP routers use wildcard SNI matching for plain TCP/STARTTLS protocols and passthrough only on implicit TLS ports.

### Troubleshooting

- If `init-mail.sh` or `init-cloud.sh` exits early, fill in the missing required env variable reported by the script.
- If `setup:storage` fails, confirm `s3fs` is installed and that `mail/data/email-data` is not already mounted.
- If Nextcloud is reachable but redirects incorrectly, verify `HERMES_HOSTNAME`, `HERMES_CLOUD_BASEPATH`, and `HERMES_INGRESS_SUBNET`, then rerun `./init-cloud.sh` to regenerate `hermes.config.php`.

Documentation: [Research Paper](https://angeloreale.notion.site/Lady-Science-100-Days-of-Products-Day-012-DreamLetter-Angelo-Reale-078155e635a747e8b06ba1c67ec28bfe?pvs=4)

Dev Environment: https://dev.dreampip.com/letters

Prod Environment: https://www.dreampip.com/letters

License: HPL3-ECO-AND-ANC 2021—Present

Purizu di Angelo Reale Caldeira de Lemos dba DreamPip

IT02925300903
