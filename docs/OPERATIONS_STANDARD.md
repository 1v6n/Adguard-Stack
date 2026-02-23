# Estándar de Documentación Operativa

## Objetivo
Definir un estándar mínimo y consistente para documentar operación, despliegue, seguridad y recuperación del stack (`AdGuard + Nginx + DuckDNS + Let's Encrypt`) de forma reproducible.

## Principios
- **Ejecutable**: cada procedimiento debe incluir comandos copy/paste.
- **Verificable**: cada paso crítico debe tener una validación esperada.
- **Versionado**: documentación y cambios operativos se actualizan en el mismo commit/PR.
- **Mínima ambigüedad**: usar rutas absolutas o `cwd` explícito (`cd /ruta/proyecto`).
- **Seguridad por defecto**: nunca incluir tokens, claves ni certificados reales.

## Estructura obligatoria
- `README.md`
  - Setup limpio desde cero.
  - Variables de entorno requeridas (`.env`).
  - Puertos expuestos y propósito.
- `docs/runbook.md`
  - Operación diaria: restart, logs, checks, backups.
  - Procedimientos de recuperación.
- `docs/troubleshooting.md`
  - Fallas reales conocidas con diagnóstico y solución.
- `docs/OPERATIONS_STANDARD.md` (este documento)
  - Reglas para mantener calidad documental.

## Formato por procedimiento
Cada procedimiento nuevo debe incluir:
1. **Propósito** (qué resuelve).
2. **Precondiciones** (permisos, puertos, servicios, variables).
3. **Comandos** (bloque shell único y ordenado).
4. **Validación** (comandos + resultado esperado).
5. **Rollback/Salida** (cómo deshacer o volver a estado estable).

## Requisitos mínimos de contenido operativo
- Flujo de bootstrap (local y VM) con orden real de ejecución.
- Política TLS (LE-first, fallback explícito, renovación automática).
- Definir una única estrategia de renovación activa (timer `systemd` o `certbot-renew`, no ambas).
- Ciclo completo de timer: instalar, estado, desinstalar.
- Checklist de seguridad de puertos en OCI.
- Pasos de rotación de secretos en caso de exposición.

## Regla de actualización
Cualquier cambio en:
- scripts en `scripts/`
- variables en `.env.example`
- puertos o comportamiento en `docker-compose.yml`
debe reflejarse en `README.md` y, si aplica, en `runbook`/`troubleshooting` dentro del mismo PR.

## Checklist para PR Operativo
- [ ] `docker compose config` sin errores.
- [ ] Script nuevo/actualizado con `bash -n`.
- [ ] README actualizado (uso + variables nuevas).
- [ ] Runbook/Troubleshooting actualizado si cambió comportamiento de operación.
- [ ] Sin secretos en diff (`.env`, tokens, claves privadas).

## Convenciones de comandos en documentación
- Prefijar con `sudo` cuando sea obligatorio.
- No mezclar comandos de distintos paths sin indicar `cd`.
- Evitar placeholders ambiguos; usar ejemplos explícitos:
  - `PUBLIC_DOMAIN="myadguardstack.duckdns.org"`
  - `INSTALL_RENEW_TIMER="true"`
