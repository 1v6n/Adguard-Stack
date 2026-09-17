# Troubleshooting Guide

Default directory: `~/adguard-stack` (or `/opt/adguard-stack` if deployed with `bootstrap-vm.sh`).

## Common Incidents and Solutions

### 1. Port 53 bind error (address already in use)
- **Cause**: Host DNS resolver (`systemd-resolved`) is listening on port 53.
- **Diagnosis**:
  ```bash
  sudo ss -ltnup | grep ':53 '
  ```
- **Fix**:
  ```bash
  sudo mkdir -p /etc/systemd/resolved.conf.d
  cat <<'CFG' | sudo tee /etc/systemd/resolved.conf.d/no-stub.conf
  [Resolve]
  DNSStubListener=no
  DNSStubListenerExtra=
  CFG
  sudo systemctl restart systemd-resolved
  ```

### 2. Compose file not found
- **Cause**: `docker compose` was run outside the project repository.
- **Fix**:
  ```bash
  cd ~/adguard-stack
  docker compose ps
  ```

### 3. Permission denied reading .env
- **Cause**: Root created `.env` with restrictive permissions.
- **Fix**:
  ```bash
  sudo chown "$USER:$USER" .env
  chmod 600 .env
  ```

### 4. Nginx crash loop on missing TLS certificate
- **Cause**: Certificate files are missing in `letsencrypt/live/<domain>/`.
- **Fix**:
  Run certificate issuance before starting Nginx:
  ```bash
  sudo ./scripts/issue-letsencrypt.sh
  docker compose restart nginx
  ```
  Use `ALLOW_SELF_SIGNED_FALLBACK="true"` only as a temporary recovery fallback.

### 5. "No route to host" when curling public IP from inside the VM
- **Cause**: Cloud provider hairpin routing limits on the public interface.
- **Fix**: Test locally against `127.0.0.1` inside the VM, and test the public domain from an external network.

### 6. Syntax error in .env: command not found
- **Cause**: Unquoted time string in `RENEW_TIMER_ONCALENDAR`.
- **Fix**:
  ```bash
  sed -i 's/^RENEW_TIMER_ONCALENDAR=.*/RENEW_TIMER_ONCALENDAR="*-*-* 03:17:00"/' .env
  ```

### 7. HTTP 502 Bad Gateway from Nginx
- **Cause**: Mismatched mount paths between commands, or AdGuard is still unconfigured (`/install.html`).
- **Fix**:
  ```bash
  sudo docker inspect adguard --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}'
  ```
  Ensure all commands run from the same stack directory.

### 8. Duplicate renewals or recurring Nginx reloads
- **Cause**: Both the systemd renewal timer and the `certbot-renew` container are running.
- **Fix**:
  ```bash
  # Check timer status and stop the container
  ./scripts/renew-timer-status.sh
  docker compose stop certbot-renew
  ```

### 9. HTTP 403 Forbidden on AdGuard dashboard
- **Cause**: Client IP is outside allowed NetBird VPN subnets (`100.64.0.0/10` or private ranges). This happens when connecting without NetBird active, or when `<PUBLIC_DOMAIN>` resolves to the VM's public IP rather than its NetBird IP.
- **Fix**:
  1. Confirm NetBird is connected: `netbird status`.
  2. In NetBird Admin Console under **DNS** > **Nameservers**, add a Match Domain rule routing `<PUBLIC_DOMAIN>` to `<NETBIRD_IP>`.
  3. Or open the diagnostic UI directly at `http://<NETBIRD_IP>:3000`.

## Quick Validation Sequence
```bash
cd ~/adguard-stack
sudo docker compose ps
curl -v http://127.0.0.1:80
curl -vk https://127.0.0.1:443
# optional (direct AdGuard diagnostics only):
# curl -v http://127.0.0.1:3000
```

## Port Policy and Base Operations
- For port policy and daily operations, see `docs/runbook.md`.
