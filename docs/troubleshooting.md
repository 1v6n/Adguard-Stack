# Guía de Troubleshooting

> Ruta canónica recomendada para operación manual: `~/adguard-stack`.
> Usa `/opt/adguard-stack` solo si desplegaste con `bootstrap-vm.sh`.

## Incidentes Detectados y Soluciones

### 1) `failed to bind host port ... :53 ... address already in use`
- **Causa**: El servicio DNS del host (`systemd-resolved`) ya está escuchando en el puerto `53`.
- **Diagnóstico**:
  ```bash
  sudo ss -ltnup | grep ':53 '
  ```
- **Solución**:
  ```bash
  sudo mkdir -p /etc/systemd/resolved.conf.d
  cat <<'CFG' | sudo tee /etc/systemd/resolved.conf.d/no-stub.conf
  [Resolve]
  DNSStubListener=no
  DNSStubListenerExtra=
  CFG
  sudo systemctl restart systemd-resolved
  ```

### 2) `no configuration file provided: not found`
- **Causa**: `docker compose` se ejecuta fuera del directorio del proyecto.
- **Solución**:
  ```bash
  cd ~/adguard-stack
  # o, si usaste bootstrap remoto:
  # cd /opt/adguard-stack
  docker compose ps
  ```

### 3) `.env` permission denied
- **Causa**: `.env` fue creado por root y el usuario operativo no puede leerlo.
- **Solución**:
  ```bash
  # stack local:
  sudo chown "$USER:$USER" ~/adguard-stack/.env
  chmod 600 ~/adguard-stack/.env
  # stack remoto:
  # sudo chown <user>:<group> /opt/adguard-stack/.env
  ```

### 4) Nginx en crash loop: certificado faltante
- **Causa**: Los archivos TLS no existen aún en `letsencrypt/live/<domain>/`.
- **Solución**:
  - Flujo recomendado: LE-first (`ALLOW_SELF_SIGNED_FALLBACK=false`), emitir certificado antes de iniciar `nginx`.
  - Contingencia: usar self-signed solo con `ALLOW_SELF_SIGNED_FALLBACK=true`.

### 5) `No route to host` al hacer curl a la IP pública desde la VM
- **Causa**: Comportamiento de red/cloud (hairpin o ruta interna).
- **Solución**: validar internamente por `127.0.0.1` y validar externamente desde otro host.

### 6) `/home/.../.env: line ... 03:17:00: command not found`
- **Causa**: `RENEW_TIMER_ONCALENDAR` sin comillas en `.env`.
- **Solución**:
  ```bash
  sed -i 's/^RENEW_TIMER_ONCALENDAR=.*/RENEW_TIMER_ONCALENDAR="*-*-* 03:17:00"/' .env
  ```

### 7) `502 Bad Gateway` con Nginx arriba pero AdGuard inaccesible
- **Causa**: desalineación de rutas/proyectos (stack levantado desde un directorio, configuración editada en otro) o AdGuard en estado first-run (`/install.html`).
- **Solución**:
  ```bash
  sudo docker inspect adguard --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}'
  # editar configuración en el path real montado y reiniciar desde ese mismo proyecto
  ```

### 8) Renovación duplicada o reinicios inesperados de Nginx
- **Causa**: timer `systemd` y contenedor `certbot-renew` activos a la vez.
- **Solución**:
  ```bash
  # modo recomendado
  ./scripts/renew-timer-status.sh
  docker compose stop certbot-renew

  # modo fallback (sin systemd)
  sudo ./scripts/uninstall-renew-timer.sh
  docker compose up -d certbot-renew
  ```

## Secuencia de Validación Rápida
```bash
cd ~/adguard-stack
sudo docker compose ps
curl -v http://127.0.0.1:80
curl -vk https://127.0.0.1:443
# opcional (solo diagnóstico de AdGuard directo):
# curl -v http://127.0.0.1:3000
```

## Referencia de puertos y operación base
- Para política de puertos y operación diaria, ver `docs/runbook.md`.
