# What is automated (checklist)

| Requirement | Automated? | Where | Verified by |
|---|---|---|---|
| Create server | ✅ | `terraform/main.tf` | `terraform apply` |
| Cloud firewall (22/80/443/ICMP) | ✅ | `hcloud_firewall.web` | Hetzner console |
| Non-root admin user + SSH key | ✅ | cloud-init template | smoke: key login works |
| Root SSH login disabled | ✅ | `00-hardening.conf` | smoke: root refused |
| Password SSH disabled | ✅ | `00-hardening.conf` | smoke: password refused |
| AllowUsers / MaxAuthTries / X11 off | ✅ | `sshd_hardening.conf.j2` | `sshd -T` |
| Host firewall (UFW default-deny) | ✅ | `roles/base` | smoke: ufw active; :8000 closed |
| SSH rate-limit + fail2ban | ✅ | `roles/base` | smoke: fail2ban active |
| Automatic security updates | ✅ | `20auto-upgrades` | smoke: setting present |
| Web server (nginx) | ✅ | `roles/nginx` | HTTPS 200 |
| HTTPS cert – Let's Encrypt (domain) | ✅ | certbot webroot | browser / `certbot certificates` |
| HTTPS cert – self-signed (no domain) | ✅ | openssl task | curl -k |
| HTTP→HTTPS redirect | ✅ | vhost | smoke: 301 |
| Reverse proxy to app | ✅ | vhost + gunicorn | smoke: /api/info |
| Sample app deployed, sandboxed systemd | ✅ | `roles/app` | smoke: /health |
| Cert auto-renewal + nginx reload hook | ✅ (LE mode) | certbot.timer + hook | `certbot renew --dry-run` |
| Destroy & rebuild with timings | ✅ | `scripts/rebuild_demo.sh` | `docs/timings-*.md` |
| CI lint/validate | ✅ | `.github/workflows/ci.yml` | Actions tab |

## Manual / not automated
- Creating the cloud account, API token and SSH key
- DNS A records for the domain
- Remote Terraform state, backups, monitoring/alerting, log shipping
- Rebooting for kernel updates
- App release pipeline / rollback
