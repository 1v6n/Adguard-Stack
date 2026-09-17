# Operational Documentation Standard

## Purpose
Standards for deploying, securing, operating, and recovering this stack (`AdGuard + Nginx + DuckDNS + Let's Encrypt`).

## Principles
- **Executable**: every procedure provides ready-to-run commands.
- **Verifiable**: every step includes an expected verification check.
- **Versioned**: update documentation and code in the same commit.
- **Explicit**: use absolute paths or set the directory explicitly with `cd`.
- **Secret-free**: never commit tokens, passwords, private keys, or certificates.

## Structure
- `README.md`: prerequisites, setup, ports, and environment variables.
- `docs/runbook.md`: maintenance, backups, validation, and recovery.
- `docs/troubleshooting.md`: incident diagnoses and verified fixes.
- `docs/OPERATIONS_STANDARD.md`: documentation rules and checklist.

## Procedure Format
## Procedure Format
Every procedure must include:
1. **Purpose**: what problem it solves.
2. **Preconditions**: required permissions, ports, services, and variables.
3. **Commands**: single ordered shell block.
4. **Validation**: verification command and expected output.
5. **Rollback**: how to return to a stable state.

## Minimum Content Requirements
- Bootstrap flow (local and VM) with real execution order.
- TLS policy (Let's Encrypt first, explicit fallback, automatic renewal).
- Single active renewal strategy (`systemd` timer or `certbot-renew` container, never both).
- Timer lifecycle: install, status check, uninstall.
- OCI port and firewall policy.
- Secret rotation steps if credentials leak.

## Change Rule
Updating any of the following requires updating `README.md` and related docs in the same commit:
- Scripts in `scripts/`
- Variables in `.env.example`
- Ports or service definitions in `docker-compose.yml`

## Operational PR Checklist
- [ ] `docker compose config` passes without errors.
- [ ] New/updated scripts pass `bash -n`.
- [ ] README updated (usage + new variables).
- [ ] Runbook/Troubleshooting updated if operational behavior changed.
- [ ] No secrets in diff (`.env`, tokens, private keys).

## Command Conventions in Docs
- Prefix with `sudo` when required.
- Do not mix commands from different paths without an explicit `cd`.
- Avoid ambiguous placeholders; use explicit examples:
  - `PUBLIC_DOMAIN="myadguardstack.duckdns.org"`
  - `INSTALL_RENEW_TIMER="true"`
