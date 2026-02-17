# AdGuard Stack

Infraestructura local basada en contenedores para DNS seguro con AdGuard Home, proxy TLS con Nginx, actualización dinámica de DNS (DuckDNS) y renovación de certificados.

## Estructura
- `docker-compose.yml`: definición de servicios y red.
- `nginx_conf/default.conf`: proxy HTTPS y endpoint DoH (`/dns-query`).
- `config/adguard/`: configuración y datos persistentes de AdGuard.
- `letsencrypt/`: certificados y estado de renovación.
- `scripts/`: automatización operativa (`up.sh`, `logs.sh`, `check.sh`, `backup.sh`, `preflight.sh`, `configure-adguard.sh`, `issue-letsencrypt.sh`, `renew-letsencrypt.sh`, `install-renew-timer.sh`, `uninstall-renew-timer.sh`, `renew-timer-status.sh`, `bootstrap-vm.sh`, `bootstrap-local.sh`).
- `docs/runbook.md`: procedimientos de operación y recuperación.
- `docs/troubleshooting.md`: errores comunes y resolución paso a paso.
- `.gitlab-ci.yml`: validaciones CI de Compose y Nginx.

## Requisitos
- Docker Engine + Docker Compose plugin.
- Puertos disponibles: `53`, `80`, `443`, `853`, `3000`.
- Acceso a dominio DuckDNS configurado.

## Configuración de entorno
```bash
cp .env.example .env
```
- Edita `PUBLIC_DOMAIN`, `DUCKDNS_SUBDOMAINS`, `DUCKDNS_TOKEN`, `ADGUARD_ADMIN_USER`, `ADGUARD_ADMIN_PASSWORD`, `LETSENCRYPT_EMAIL`, `LETSENCRYPT_STAGING`, `ALLOW_SELF_SIGNED_FALLBACK`, `INSTALL_RENEW_TIMER`, `RENEW_TIMER_ONCALENDAR` y `RENEW_TIMER_RANDOMIZED_DELAY` en `.env`.

## Inicio rápido
```bash
./scripts/up.sh
```

## Bootstrap remoto (clona/actualiza en `/opt/adguard-stack`)
Úsalo cuando ejecutas el script desde cualquier ruta y quieres que el script gestione clone/pull:
```bash
sudo REPO_URL="https://github.com/1v6n/adguard-stack.git" \
PUBLIC_DOMAIN="myadguardzi.duckdns.org" \
DUCKDNS_SUBDOMAINS="myadguardzi" \
DUCKDNS_TOKEN="TU_TOKEN" \
ADGUARD_ADMIN_USER="admin" \
ADGUARD_ADMIN_PASSWORD="CAMBIAR_PASSWORD" \
LETSENCRYPT_EMAIL="you@example.com" \
LETSENCRYPT_STAGING="false" \
ALLOW_SELF_SIGNED_FALLBACK="false" \
INSTALL_RENEW_TIMER="true" \
bash /ruta/al/bootstrap-vm.sh
```
El bootstrap ejecuta `scripts/preflight.sh`, levanta servicios core sin `nginx`, aplica configuración headless de AdGuard, emite Let's Encrypt, inicia `nginx` y registra un timer `systemd` para renovación automática (si `INSTALL_RENEW_TIMER=true`). Si falla la emisión, aborta salvo que `ALLOW_SELF_SIGNED_FALLBACK=true`.

## Bootstrap local (ya estás dentro del repo)
Úsalo cuando ya clonaste el repositorio y quieres evitar un segundo clone:
```bash
git clone https://github.com/1v6n/adguard-stack.git
cd adguard-stack
sudo PUBLIC_DOMAIN="tu-subdominio.duckdns.org" \
DUCKDNS_SUBDOMAINS="tu-subdominio" \
DUCKDNS_TOKEN="TU_TOKEN" \
ADGUARD_ADMIN_USER="admin" \
ADGUARD_ADMIN_PASSWORD="CAMBIAR_PASSWORD" \
LETSENCRYPT_EMAIL="you@example.com" \
LETSENCRYPT_STAGING="false" \
ALLOW_SELF_SIGNED_FALLBACK="false" \
INSTALL_RENEW_TIMER="true" \
bash scripts/bootstrap-local.sh
```

## Setup limpio desde cero (recomendado)
```bash
git clone https://github.com/1v6n/adguard-stack.git
cd adguard-stack
sudo PUBLIC_DOMAIN="tu-subdominio.duckdns.org" \
DUCKDNS_SUBDOMAINS="tu-subdominio" \
DUCKDNS_TOKEN="TU_TOKEN" \
ADGUARD_ADMIN_USER="admin" \
ADGUARD_ADMIN_PASSWORD="CAMBIAR_PASSWORD" \
LETSENCRYPT_EMAIL="you@example.com" \
LETSENCRYPT_STAGING="false" \
ALLOW_SELF_SIGNED_FALLBACK="false" \
INSTALL_RENEW_TIMER="true" \
bash scripts/bootstrap-local.sh
```

## Renovación de Let's Encrypt
Ejecuta renovación manual:
```bash
./scripts/renew-letsencrypt.sh
```
El script reinicia `nginx` solo si detecta cambios en certificados.

Para instalar/reinstalar timer automático manualmente:
```bash
sudo ./scripts/install-renew-timer.sh
```

Ver estado del timer y últimos/ próximos ciclos:
```bash
./scripts/renew-timer-status.sh
```

Desinstalar timer automático:
```bash
sudo ./scripts/uninstall-renew-timer.sh
```

Previsualizar desinstalación sin cambios:
```bash
sudo DRY_RUN=true ./scripts/uninstall-renew-timer.sh
```

## Verificación
```bash
./scripts/check.sh
```

## Logs
```bash
./scripts/logs.sh
# o últimas 200 líneas
./scripts/logs.sh 200
```

## Backups
```bash
./scripts/backup.sh
# conservar 14 backups
KEEP_BACKUPS=14 ./scripts/backup.sh
```

## Operación básica
- Reiniciar proxy Nginx:
  ```bash
  docker compose restart nginx
  ```
- Ver estado de contenedores:
  ```bash
  docker compose ps
  ```

## Notas de seguridad
- No subas tokens o claves privadas a repositorios públicos.
- Usa `.env` para datos sensibles (DuckDNS token/subdominio) y mantén `.env` fuera del control de versiones.

## Puertos a abrir en Oracle Cloud (OCI)
- `22/tcp`: solo desde tu IP de administración (SSH).
- `80/tcp`: público (`0.0.0.0/0`) para HTTP y redirección.
- `443/tcp`: público (`0.0.0.0/0`) para HTTPS/DoH vía Nginx.
- `53/tcp` y `53/udp`: DNS (idealmente restringido a tus clientes/CIDR de confianza).
- `853/tcp`: DNS-over-TLS (DoT).
- `853/udp`: abrir solo si vas a usar DoQ.
- `3000/tcp`: solo para setup inicial de AdGuard; luego cerrar o restringir.
- `8443/tcp`: no requerido en la configuración actual.
