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
- Puertos usados por defecto en operación: `53`, `80`, `443`, `853`.
- `3000` queda publicado solo en loopback (`127.0.0.1`) para diagnóstico/recuperación manual de AdGuard.
- Acceso a dominio DuckDNS configurado.

## Configuración de entorno
```bash
cp .env.example .env
```
- Edita `PUBLIC_DOMAIN`, `DUCKDNS_SUBDOMAINS`, `DUCKDNS_TOKEN`, `ADGUARD_ADMIN_USER`, `ADGUARD_ADMIN_PASSWORD`, `LETSENCRYPT_EMAIL`, `LETSENCRYPT_STAGING`, `ALLOW_SELF_SIGNED_FALLBACK`, `INSTALL_RENEW_TIMER`, `RENEW_TIMER_ONCALENDAR` y `RENEW_TIMER_RANDOMIZED_DELAY` en `.env`.

## Primer despliegue local (recomendado)
Ejecútalo dentro del repositorio:
```bash
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

Si aún no clonaste el repositorio:
```bash
git clone https://github.com/1v6n/adguard-stack.git
cd adguard-stack
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
bash /ruta/al/adguard-stack/scripts/bootstrap-vm.sh
```
El bootstrap ejecuta `scripts/preflight.sh`, levanta servicios core sin `nginx`, aplica configuración headless de AdGuard, emite Let's Encrypt, inicia `nginx` y configura renovación automática: timer `systemd` si `INSTALL_RENEW_TIMER=true`, o contenedor `certbot-renew` si `INSTALL_RENEW_TIMER=false`. Si falla la emisión, aborta salvo que `ALLOW_SELF_SIGNED_FALLBACK=true`.

## Operación diaria (stack ya inicializado)
```bash
./scripts/up.sh
```

## Checklist post-bootstrap
- `sudo docker compose ps`
- `./scripts/renew-timer-status.sh`
- `curl -vk https://<PUBLIC_DOMAIN>`
- Verificar emisor de certificado con:
  - `echo | openssl s_client -connect "<PUBLIC_DOMAIN>:443" -servername "<PUBLIC_DOMAIN>" 2>/dev/null | openssl x509 -noout -issuer -subject -dates`

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
- `443/tcp`: HTTPS/DoH vía Nginx.
- `853/tcp`: DoT.
- Opcionales según caso: `80/tcp` (redirección HTTP), `53/tcp+udp` (DNS clásico), `853/udp` (DoQ).
- `3000/tcp` no se abre en OCI: queda en loopback local para diagnóstico.
- Política detallada y criterio operativo en `docs/runbook.md`.

## Referencias operativas
- Operación diaria, renovación de certificados y lifecycle del timer: `docs/runbook.md`.
- Incidentes frecuentes y resolución: `docs/troubleshooting.md`.
- Estándar de documentación para cambios futuros: `docs/OPERATIONS_STANDARD.md`.
