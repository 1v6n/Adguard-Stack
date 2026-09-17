# AdGuard Stack

Docker stack running AdGuard Home behind an Nginx TLS proxy with DuckDNS dynamic DNS and automated Let's Encrypt certificates.

## Structure
- `docker-compose.yml`: service definitions, networks, and port bindings.
- `nginx_conf/default.conf`: HTTPS reverse proxy, NetBird access control, and DoH endpoint (`/dns-query`).
- `config/adguard/`: persistent AdGuard configuration and query data.
- `letsencrypt/`: TLS certificates and renewal state.
- `scripts/`: deployment, verification, backup, and renewal automation.
- `docs/runbook.md`: operational routines, port policies, and recovery steps.
- `docs/troubleshooting.md`: common failures and verified fixes.

## Requirements
- Docker Engine with Compose plugin.
- NetBird installed and connected on the host (`netbird status` or `wt0` interface).
- Port layout:
  - Public: `443` (DoH on `/dns-query`), `80` (optional HTTP-to-HTTPS redirect).
  - Private (NetBird only): `53` (DNS), `3000` (AdGuard setup/UI), and `853` (DoT) bound to `NETBIRD_IP`.
  - Dashboard: restricted to NetBird clients (`100.64.0.0/10` and private subnets) and localhost.
- A DuckDNS domain and token.

## Environment Setup
```bash
cp .env.example .env
```
Edit `.env` with your domain, credentials, and NetBird IP (`netbird status` or `ip -4 addr show wt0`).

## First Local Deployment (Recommended)
Run inside the repository:
```bash
sudo PUBLIC_DOMAIN="your-subdomain.duckdns.org" \
DUCKDNS_SUBDOMAINS="your-subdomain" \
DUCKDNS_TOKEN="YOUR_TOKEN" \
ADGUARD_ADMIN_USER="admin" \
ADGUARD_ADMIN_PASSWORD="CHANGE_PASSWORD" \
LETSENCRYPT_EMAIL="you@example.com" \
LETSENCRYPT_STAGING="false" \
ALLOW_SELF_SIGNED_FALLBACK="false" \
INSTALL_RENEW_TIMER="true" \
bash scripts/bootstrap-local.sh
```

If you have not cloned the repository yet:
```bash
git clone https://github.com/1v6n/adguard-stack.git
cd adguard-stack
```

## Remote Bootstrap (clone/update in `/opt/adguard-stack`)
Use this when running from any location and you want the script to manage clone/pull:
```bash
sudo REPO_URL="https://github.com/1v6n/adguard-stack.git" \
PUBLIC_DOMAIN="myadguardzi.duckdns.org" \
DUCKDNS_SUBDOMAINS="myadguardzi" \
DUCKDNS_TOKEN="YOUR_TOKEN" \
ADGUARD_ADMIN_USER="admin" \
ADGUARD_ADMIN_PASSWORD="CHANGE_PASSWORD" \
LETSENCRYPT_EMAIL="you@example.com" \
LETSENCRYPT_STAGING="false" \
ALLOW_SELF_SIGNED_FALLBACK="false" \
INSTALL_RENEW_TIMER="true" \
bash /path/to/adguard-stack/scripts/bootstrap-vm.sh
```
Bootstrap runs `scripts/preflight.sh`, starts core services without `nginx`, applies headless AdGuard setup, issues Let's Encrypt certificates, then starts `nginx`. Renewal mode is selected automatically: `systemd` timer when `INSTALL_RENEW_TIMER=true`, or `certbot-renew` container when `INSTALL_RENEW_TIMER=false`. If issuance fails, bootstrap aborts unless `ALLOW_SELF_SIGNED_FALLBACK=true`.

## Daily Operation (initialized stack)
```bash
./scripts/up.sh
```

## Post-Bootstrap Checklist
- `sudo docker compose ps`
- `./scripts/renew-timer-status.sh`
- `curl -vk https://<PUBLIC_DOMAIN>`
- Verify the served certificate:
  - `echo | openssl s_client -connect "<PUBLIC_DOMAIN>:443" -servername "<PUBLIC_DOMAIN>" 2>/dev/null | openssl x509 -noout -issuer -subject -dates`

## Validation
```bash
./scripts/check.sh
```

## Logs
```bash
./scripts/logs.sh
# last 200 lines
./scripts/logs.sh 200
```

## Backups
```bash
./scripts/backup.sh
# keep 14 backups
KEEP_BACKUPS=14 ./scripts/backup.sh
```

## Basic Operations
- Restart Nginx proxy:
  ```bash
  docker compose restart nginx
  ```
- Check container status:
  ```bash
  docker compose ps
  ```

## Security Notes
- Never commit tokens or private keys to public repositories.
- Keep sensitive values in `.env` and out of version control.

## OCI Security List Policy
- `443/tcp`: Open to `0.0.0.0/0` for DoH (`/dns-query`). Dashboard access on `/` returns HTTP 403 for non-VPN IPs.
- `51820/udp`: Open to `0.0.0.0/0` for direct NetBird WireGuard connections.
- `53/udp & 53/tcp`: Keep closed in OCI to prevent open resolver attacks. Available only within NetBird.
- `3000/tcp & 853/tcp+udp`: Keep closed in OCI. Bound strictly to `NETBIRD_IP`.
- `22/tcp`: Keep closed if possible. Use NetBird SSH (`netbird ssh` or SSH over `NETBIRD_IP`).
- `80/tcp`: Optional. Open only if HTTP-to-HTTPS redirect is required.
- Full details in `docs/runbook.md`.

## Operational References
- Operations, renewals, and timer lifecycle: `docs/runbook.md`.
- Incidents and fixes: `docs/troubleshooting.md`.
- Documentation standards: `docs/OPERATIONS_STANDARD.md`.
