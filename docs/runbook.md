# Operations Runbook

## Clean Installation
1. Configure environment variables:
   ```bash
   cp .env.example .env
   ```
   Fill in required values in `.env`: `PUBLIC_DOMAIN`, `DUCKDNS_SUBDOMAINS`, `DUCKDNS_TOKEN`, `NETBIRD_IP`, `ADGUARD_ADMIN_USER`, `ADGUARD_ADMIN_PASSWORD`, and `LETSENCRYPT_EMAIL`.
2. Run the bootstrap script:
   ```bash
   sudo bash scripts/bootstrap-local.sh
   ```
3. Verify running containers:
   ```bash
   sudo docker compose ps
   ```
4. Check renewal timer status:
   ```bash
   ./scripts/renew-timer-status.sh
   ```
   When `INSTALL_RENEW_TIMER=true`, the `certbot-renew` container remains stopped while the systemd timer runs renewals.

## Functional Validation
1. From outside NetBird (public internet):
   - Dashboard check: `curl -I https://<PUBLIC_DOMAIN>/` must return HTTP 403 Forbidden.
   - Public DNS check: `dig @<OCI_PUBLIC_IP> google.com` must time out or refuse connections.
   - DoH check: `curl -sS -H "accept: application/dns-message" "https://<PUBLIC_DOMAIN>/dns-query?dns=AAABAAABAAAAAAAAB2V4YW1wbGUDY29tAAABAAE"` must return raw DNS records.
2. From inside NetBird:
   - Dashboard: open `https://<PUBLIC_DOMAIN>/` (with NetBird DNS routing active) or `http://<NETBIRD_IP>:3000`.
   - DNS resolution: `dig @<NETBIRD_IP> google.com` resolves with AdGuard filtering.
3. Review logs: `./scripts/logs.sh 200`.
4. Validate served certificate:
   ```bash
   echo | openssl s_client -connect "<PUBLIC_DOMAIN>:443" -servername "<PUBLIC_DOMAIN>" 2>/dev/null | openssl x509 -noout -issuer -subject -dates
   ```
5. Verify port isolation: ports 53, 3000, and 853 must bind only to `NETBIRD_IP` and remain closed in OCI Security Lists.

## Certificate Renewal
- Recommended mode (Linux with systemd): `adguard-renew.timer`.
  - Manual renewal:
    - `./scripts/renew-letsencrypt.sh`
  - Install/reinstall timer:
    - `sudo ./scripts/install-renew-timer.sh`
  - Check status:
    - `./scripts/renew-timer-status.sh`
  - Uninstall timer:
    - `sudo ./scripts/uninstall-renew-timer.sh`
- Fallback mode (without systemd): `certbot-renew` container.
  - `./scripts/renew-letsencrypt.sh`
  - `docker compose up -d certbot-renew`

## Basic Recovery
1. If Nginx fails, validate config syntax:
   - `docker compose exec nginx nginx -t`
2. Restart affected service:
   - `docker compose restart nginx`
   - `docker compose restart adguard`
3. If issue persists, restart full stack:
   - `docker compose down && docker compose up -d`
4. If bootstrap fails during certificate issuance:
   - validate domain DNS (`dig +short <PUBLIC_DOMAIN>`)
   - inspect `duckdns` and `nginx` logs
   - use `ALLOW_SELF_SIGNED_FALLBACK="true"` only as temporary contingency

## Post-Incident Checklist
- Containers are `Up` in `docker compose ps`.
- Certificates exist under `letsencrypt/live/`.
- DNS resolution and HTTPS access are restored.

## Secret Rotation
- Rotate immediately if any of these are exposed:
  - `DUCKDNS_TOKEN`
  - `ADGUARD_ADMIN_PASSWORD`
- Update `.env`, restart services, and validate access:
  - `sudo docker compose restart duckdns adguard nginx`

## OCI Firewall and NetBird Port Policy
- `443/tcp`: Open to `0.0.0.0/0` for HTTPS and DoH. Non-VPN access to `/` receives HTTP 403.
- `51820/udp`: Open to `0.0.0.0/0` for direct NetBird WireGuard connections.
- `53/tcp` & `53/udp`: Keep closed in OCI to prevent open resolver attacks. Available only over NetBird (`<NETBIRD_IP>:53`).
- `3000/tcp` & `853/tcp+udp`: Keep closed in OCI. Bound strictly to `NETBIRD_IP`.
- `22/tcp`: Keep closed if possible. Use NetBird SSH (`netbird ssh` or SSH over `NETBIRD_IP`).
- `80/tcp`: Open only if you need HTTP-to-HTTPS redirect.

## NetBird DNS Routing for Valid TLS
1. In the NetBird Admin Console under **DNS** > **Add Nameserver**:
   - Set the nameserver address to `<NETBIRD_IP>`.
   - Add a Match Domain rule for `<PUBLIC_DOMAIN>` pointing to this nameserver.
2. With NetBird active, opening `https://<PUBLIC_DOMAIN>` routes directly over WireGuard to Nginx, validating the Let's Encrypt certificate without browser warnings.

## Incident Playbooks
See `docs/troubleshooting.md` for known errors and recovery steps.

## Backups
Run `./scripts/backup.sh` before major configuration changes. Verified archives are saved in `backups/`.
