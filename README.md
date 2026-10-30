# PKHosting – Server Provisioning with Infrastructure as Code

One repeatable process that builds, secures and deploys a hosting-style web server
from a blank cloud account: **Terraform** creates the VM + cloud firewall, **Ansible**
configures the OS, TLS, reverse proxy and sample app. A single script destroys and
rebuilds everything and prints timings.

```
 you ──► terraform apply ──► Hetzner VM (Ubuntu 24.04, cloud-init creates `deploy` user)
                    └──► ansible-playbook ──► base (SSH/UFW/fail2ban/auto-updates)
                                              app  (gunicorn + Flask, systemd, 127.0.0.1:8000)
                                              nginx (TLS + reverse proxy → app)
Internet ──443──► nginx ──► gunicorn/Flask        (port 8000 never exposed)
```

## Tool choices (and why)
| Need | Tool | Reason |
|---|---|---|
| Create server + cloud firewall | Terraform (hcloud provider) | Declarative, `destroy`/`apply` is the rebuild story |
| Configure OS + deploy | Ansible | Idempotent, agentless, readable YAML |
| TLS | Let's Encrypt (certbot) if `PK_DOMAIN` set, else self-signed | Works with or without a domain |
| Reverse proxy | nginx → gunicorn → Flask | Standard production pattern |

## Prerequisites
- Terraform ≥ 1.5, Ansible ≥ 2.15, `ssh`, `curl`, bash (Linux/macOS/WSL)
- A Hetzner Cloud account + API token (Read & Write) and an SSH key pair (`ssh-keygen -t ed25519`)
- Optional: a domain whose A record you can point at the server IP

## Setup
```bash
git clone <this repo> && cd pkhosting-iac
cp .env.example .env            # edit: token, optional domain/email   (git-ignored)
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
source .env
./scripts/provision.sh          # build everything (~ see timings in REPORT.md)
```
- **No domain:** leave `PK_DOMAIN` empty → self-signed cert, browse `https://<ip>/` (accept the warning).
- **With domain:** `PK_DOMAIN=example.pk`, `PK_LE_EMAIL=you@example.pk`. Point the A records
  for `example.pk` and `www.example.pk` at the server IP **before** the Ansible step
  (provision.sh prints the IP after Terraform; on first run pause or run in two stages, see RUNBOOK).
  Keep `PK_LE_STAGING=1` while testing; set to `0` for a trusted production cert.

## Destroy & rebuild demo
```bash
./scripts/rebuild_demo.sh       # destroy → apply → configure → smoke test, writes docs/timings-*.md
```

## Repo layout
```
terraform/   VM, SSH key, cloud firewall, cloud-init template
ansible/     site.yml + roles: base, app, nginx
app/         sample Flask app
scripts/     provision.sh, smoke_test.sh, rebuild_demo.sh
docs/        RUNBOOK, CHECKLIST, WALKTHROUGH, COMMIT_PLAN, timings
.github/     CI: terraform validate, ansible-lint, shellcheck, secret scan
```

## Security notes
- No secrets in git: token only via `TF_VAR_hcloud_token`; `.gitignore` excludes state, tfvars, `.env`, keys.
- Only a **public** SSH key is used. Terraform state is local and **contains** server details – never commit it.

## Limitations
- Terraform state is local (no remote backend/locking) – fine for one operator, not a team.
- Rebuild changes the server IP; with a real domain you must update DNS (or add a reserved IP / DNS provider automation).
- Let's Encrypt limits duplicate certificates (5/week) – use staging while rehearsing rebuilds. Rebuild issues a new cert (not restored from backup).
- `deploy` has passwordless sudo (needed for automation; mitigated by key-only SSH).
- Single server, no load balancer, backups, monitoring or log shipping.
- App is deployed by copying a file; no CI/CD release pipeline or rollback.
- `unattended-upgrades` applies security patches but does not auto-reboot (kernel updates need a manual reboot).
- Tested target: Ubuntu 24.04. Server type names (`cx22`) change – check `hcloud server-type list`.
- SSH is open to the internet by default (rate-limited by UFW + fail2ban); restrict `allowed_ssh_cidrs` if you have a fixed IP.
