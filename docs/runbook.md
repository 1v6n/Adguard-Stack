# Runbook Operativo

## Arranque limpio (recomendado)
1. Asegurar configuración de entorno:
   - `cp .env.example .env` (si es primera vez)
   - Completar variables requeridas en `.env`:
     - `PUBLIC_DOMAIN`
     - `DUCKDNS_SUBDOMAINS`
     - `DUCKDNS_TOKEN`
     - `ADGUARD_ADMIN_USER`
     - `ADGUARD_ADMIN_PASSWORD`
     - `LETSENCRYPT_EMAIL`
2. Ejecutar bootstrap local (flujo LE-first):
   - `sudo PUBLIC_DOMAIN="tu-subdominio.duckdns.org" DUCKDNS_SUBDOMAINS="tu-subdominio" DUCKDNS_TOKEN="TU_TOKEN" ADGUARD_ADMIN_USER="admin" ADGUARD_ADMIN_PASSWORD="CAMBIAR_PASSWORD" LETSENCRYPT_EMAIL="you@example.com" LETSENCRYPT_STAGING="false" ALLOW_SELF_SIGNED_FALLBACK="false" INSTALL_RENEW_TIMER="true" bash scripts/bootstrap-local.sh`
3. Confirmar estado:
   - `sudo docker compose ps`
4. Validar timer de renovación:
   - `./scripts/renew-timer-status.sh`
   - Si `INSTALL_RENEW_TIMER=true`, el contenedor `certbot-renew` debe quedar detenido.

## Validación funcional
1. Abrir `https://<PUBLIC_DOMAIN>` y comprobar acceso a AdGuard.
2. Verificar endpoint DoH `https://<PUBLIC_DOMAIN>/dns-query`.
3. Revisar logs: `./scripts/logs.sh 200`.
4. Validar certificado servido:
   - `echo | openssl s_client -connect "<PUBLIC_DOMAIN>:443" -servername "<PUBLIC_DOMAIN>" 2>/dev/null | openssl x509 -noout -issuer -subject -dates`
5. Confirmar política de exposición:
   - `3000/tcp` está ligado a `127.0.0.1` en el host; no abrirlo en OCI.

## Renovación de certificados
- Modo recomendado (Linux con systemd): timer `adguard-renew.timer`.
  - Renovación manual:
    - `./scripts/renew-letsencrypt.sh`
  - Instalar/reinstalar timer:
    - `sudo ./scripts/install-renew-timer.sh`
  - Ver estado:
    - `./scripts/renew-timer-status.sh`
  - Desinstalar timer:
    - `sudo ./scripts/uninstall-renew-timer.sh`
- Modo fallback (sin systemd): contenedor `certbot-renew`.
  - `./scripts/renew-letsencrypt.sh`
  - `docker compose up -d certbot-renew`

## Recuperación básica
1. Si Nginx falla, validar sintaxis:
   - `docker compose exec nginx nginx -t`
2. Reiniciar servicio afectado:
   - `docker compose restart nginx`
   - `docker compose restart adguard`
3. Si persiste, reiniciar stack completo:
   - `docker compose down && docker compose up -d`
4. Si falla bootstrap por certificado:
   - validar DNS del dominio (`dig +short <PUBLIC_DOMAIN>`)
   - revisar logs de `duckdns` y `nginx`
   - usar `ALLOW_SELF_SIGNED_FALLBACK="true"` solo como contingencia temporal

## Checklist post-incidente
- Estado de contenedores `Up` en `docker compose ps`.
- Certificados presentes en `letsencrypt/live/`.
- Resolución DNS y acceso HTTPS restaurados.

## Rotación de secretos
- Rotar inmediatamente si hubo exposición de:
  - `DUCKDNS_TOKEN`
  - `ADGUARD_ADMIN_PASSWORD`
- Actualizar `.env`, reiniciar servicios y validar acceso:
  - `sudo docker compose restart duckdns adguard nginx`

## Política de puertos recomendada (OCI)
- `22/tcp`: solo IP de administración.
- `80/tcp`: público si usas redirección HTTP->HTTPS.
- `443/tcp`: público para HTTPS/DoH.
- `853/tcp`: público para DoT.
- `53/tcp` y `53/udp`: abrir solo si realmente usas DNS clásico.
- `853/udp`: abrir solo si usas DoQ.
- `3000/tcp`: no abrir (uso local en loopback únicamente).

## Incidentes y diagnóstico
- Para resolución de fallas conocidas, seguir `docs/troubleshooting.md`.

## Respaldo recomendado
- Ejecutar `./scripts/backup.sh` antes de cambios mayores.
- Verificar creación de archivo en `backups/`.
