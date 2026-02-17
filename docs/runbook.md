# Runbook Operativo

## Arranque
1. Asegurar configuración de entorno:
   - `cp .env.example .env` (si es primera vez)
   - Completar variables DuckDNS en `.env`
2. Ejecutar `./scripts/up.sh`.
3. Confirmar estado con `docker compose ps`.
4. Validar Nginx con `./scripts/check.sh`.

## Validación funcional
1. Abrir `https://myadguardzi.duckdns.org` y comprobar acceso a AdGuard.
2. Verificar endpoint DoH `https://myadguardzi.duckdns.org/dns-query`.
3. Revisar logs: `./scripts/logs.sh 200`.

## Recuperación básica
1. Si Nginx falla, validar sintaxis:
   - `docker compose exec nginx nginx -t`
2. Reiniciar servicio afectado:
   - `docker compose restart nginx`
   - `docker compose restart adguard`
3. Si persiste, reiniciar stack completo:
   - `docker compose down && docker compose up -d`

## Checklist post-incidente
- Estado de contenedores `Up` en `docker compose ps`.
- Certificados presentes en `letsencrypt/live/`.
- Resolución DNS y acceso HTTPS restaurados.

## Respaldo recomendado
- Ejecutar `./scripts/backup.sh` antes de cambios mayores.
- Verificar creación de archivo en `backups/`.
