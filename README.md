# AdGuard Stack

Infraestructura local basada en contenedores para DNS seguro con AdGuard Home, proxy TLS con Nginx, actualización dinámica de DNS (DuckDNS) y renovación de certificados.

## Estructura
- `docker-compose.yml`: definición de servicios y red.
- `nginx_conf/default.conf`: proxy HTTPS y endpoint DoH (`/dns-query`).
- `config/adguard/`: configuración y datos persistentes de AdGuard.
- `letsencrypt/`: certificados y estado de renovación.
- `scripts/`: automatización operativa (`up.sh`, `logs.sh`, `check.sh`, `backup.sh`).
- `docs/runbook.md`: procedimientos de operación y recuperación.
- `.gitlab-ci.yml`: validaciones CI de Compose y Nginx.

## Requisitos
- Docker Engine + Docker Compose plugin.
- Puertos disponibles: `53`, `80`, `443`, `853`, `3000`.
- Acceso a dominio DuckDNS configurado.

## Configuración de entorno
```bash
cp .env.example .env
```
- Edita `PUBLIC_DOMAIN`, `DUCKDNS_SUBDOMAINS` y `DUCKDNS_TOKEN` en `.env`.

## Inicio rápido
```bash
./scripts/up.sh
```

## Bootstrap para VM Linux (genérico)
Ejecuta el stack en una VM Linux nueva con instalación automática de Docker:
```bash
sudo REPO_URL="https://gitlab.com/ivan-devops1/adguard-stack.git" \
PUBLIC_DOMAIN="myadguardzi.duckdns.org" \
DUCKDNS_SUBDOMAINS="myadguardzi" \
DUCKDNS_TOKEN="TU_TOKEN" \
bash scripts/bootstrap-vm.sh
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
