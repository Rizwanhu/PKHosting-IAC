# PKHosting – Server Provisioning with Infrastructure as Code
**Task ref:** ZR-26-00740 · **Author:** Zeshan Sarwar · **Date:** [FILL]
**Repository:** [FILL: GitHub URL] · **Live URL:** [FILL: https://… or https://<ip>/ (self-signed)]

> Items marked **[FILL]** must be completed with real results from your own run. Nothing below has been invented: timings and URLs only exist once you run the pipeline.

## 1. Objective
Build, secure and deploy a hosting-style web server through one repeatable, scripted process, and prove it by destroying and rebuilding it from scratch with measured timings.

## 2. Architecture and tool choices
- **Terraform (Hetzner Cloud):** VM (Ubuntu 24.04), SSH key, cloud firewall, cloud-init that creates the non-root `deploy` user.
- **Ansible:** three roles – `base` (hardening), `app` (sample app), `nginx` (TLS + reverse proxy).
- **Request path:** Internet → :443 nginx (TLS) → 127.0.0.1:8000 gunicorn → Flask. Port 8000 is never public.
- **Two firewall layers:** Hetzner cloud firewall + host UFW (default deny incoming).
- **Why these tools:** Terraform makes destroy/rebuild a one-liner; Ansible is idempotent and agentless; both are widely used and auditable as plain text.

## 3. Requirement coverage
| Requirement | Implementation |
|---|---|
| Web server | nginx |
| Firewall | Cloud firewall (22/80/443/ICMP) + UFW default-deny, SSH rate-limited |
| Non-root user | `deploy` created by cloud-init, sudo, key-only |
| SSH hardening | root login off, passwords off, `AllowUsers`, `MaxAuthTries 3`, X11/agent forwarding off, fail2ban |
| Automatic security updates | `unattended-upgrades` + periodic config + apt timers |
| HTTPS | Let's Encrypt (certbot webroot, renewal timer + reload hook) when `PK_DOMAIN` set; otherwise self-signed with IP SAN |
| Sample app behind reverse proxy | Flask/gunicorn systemd service (sandboxed, unprivileged `pkapp` user) behind nginx; HTTP→HTTPS 301 |
| Destroy & rebuild with timings | `scripts/rebuild_demo.sh` |
| Runbook + checklist | `docs/RUNBOOK.md`, `docs/CHECKLIST.md` |

## 4. Notable engineering decisions
1. **SSH drop-in named `00-hardening.conf`.** sshd takes the first value it reads; Ubuntu cloud images ship `50-cloud-init.conf` with `PasswordAuthentication yes`, which would silently override a later-named file.
2. **cloud-init creates the admin user**, so Ansible never connects as root and root login can be disabled from the start.
3. **UFW SSH rule is added before enabling the firewall** to avoid lock-out; `sshd -t` validates config before restart.
4. **Two-stage nginx vhost for Let's Encrypt:** HTTP-only vhost serves the ACME challenge, then the full HTTPS vhost is applied once the cert exists.
5. **Let's Encrypt staging flag** protects against the 5-duplicate-certs/week rate limit during repeated rebuild rehearsals.
6. **Smoke tests assert security properties** (root/password SSH refused, port 8000 closed), not just that the site loads.
7. **Secrets:** API token supplied only via env var; state, tfvars, `.env` and keys are git-ignored; CI includes a simple secret scan.

## 5. Results (fill from your run)
**Environment:** Hetzner [FILL server type/location], domain: [FILL or none → self-signed]

### 5.1 Smoke test output
```
[FILL: paste output of scripts/smoke_test.sh – should end with ALL CHECKS PASSED]
```

### 5.2 Destroy & rebuild timings
Paste from `docs/timings-*.md` produced by `scripts/rebuild_demo.sh`:

| Stage | Run 1 (s) | Run 2 (s) |
|---|---|---|
| Terraform destroy | [FILL] | [FILL] |
| Terraform apply (create VM) | [FILL] | [FILL] |
| Wait for SSH | [FILL] | [FILL] |
| Ansible configure + deploy | [FILL] | [FILL] |
| Smoke tests | [FILL] | [FILL] |
| **Total rebuild** | [FILL] | [FILL] |

Observation: [FILL – e.g. which stage dominates; typical is Ansible package installs]

### 5.3 Idempotence
Second `ansible-playbook site.yml` result: `changed=[FILL]` (expected 0 apart from nothing).
### 5.4 Evidence screenshots
[FILL: browser HTTPS page, `ufw status`, root SSH refused, terraform apply, GitHub Actions green]

## 6. Limitations
See README "Limitations": local Terraform state, IP changes on rebuild (DNS update needed), LE rate limits, passwordless sudo for automation, no backups/monitoring/CI-CD for app releases, no auto-reboot, single server.

## 7. Possible improvements
Remote state (S3/Terraform Cloud), reserved IP + DNS automation, backup of `/etc/letsencrypt`, Prometheus/node-exporter, GitHub Actions deploy pipeline, CIS benchmark (Lynis) scan, load balancer + two nodes.

## 8. Understanding check (be ready to explain/modify)
- *Why disable root and password SSH?* Removes the most-attacked login paths; keys can't be brute-forced.
- *How do cloud firewall and UFW differ?* Cloud one filters before traffic reaches the VM; UFW protects if the cloud rules are changed/misconfigured – defense in depth.
- *What happens if I change `PK_DOMAIN`?* `tls_mode` flips to letsencrypt; Ansible runs the two-stage flow.
- *How would I add a second site?* New vhost template + `server_name`, another app/service on a different port.
- *Why gunicorn, not `flask run`?* Dev server isn't production-grade; gunicorn gives workers, supervision with systemd.
- *How do updates apply?* `apt-daily-upgrade.timer` runs unattended-upgrades for the security pocket.
- *Idempotence?* Modules declare desired state; re-runs change nothing if the state matches (`creates:` guards the openssl/certbot commands).
