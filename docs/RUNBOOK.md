# Runbook

## 1. Build (first time or after destroy)
1. `source .env` (token, optional `PK_DOMAIN`, `PK_LE_EMAIL`, `PK_LE_STAGING`).
2. `./scripts/provision.sh`
3. **Domain mode, first run only:** run `terraform -chdir=terraform apply`, read `terraform output ipv4`,
   create DNS A records (`@` and `www`), wait for propagation (`dig +short example.pk`), then
   `cd ansible && ansible-playbook site.yml`. Let's Encrypt fails if DNS doesn't point at the server yet.
4. Verify: `./scripts/smoke_test.sh $(terraform -chdir=terraform output -raw ipv4)`

## 2. Destroy & rebuild
`./scripts/rebuild_demo.sh` – records stage timings to `docs/timings-<date>.md`.
Domain mode: after rebuild the IP changes → update DNS and re-run `ansible-playbook site.yml`
(or use self-signed mode for timing demos).

## 3. Re-apply configuration only (idempotent)
`cd ansible && ansible-playbook site.yml` – safe to repeat; should report `changed=0` on a settled server.

## 4. Deploy a new app version
Edit `app/app.py`, commit, run `ansible-playbook site.yml --tags` (or full run). Handler restarts `pkapp`.

## 5. Routine operations
| Task | Command (on server as `deploy`) |
|---|---|
| App logs | `journalctl -u pkapp -f` |
| nginx logs | `sudo tail -f /var/log/nginx/error.log` |
| Firewall | `sudo ufw status verbose` |
| Banned IPs | `sudo fail2ban-client status sshd` |
| Pending auto-updates log | `less /var/log/unattended-upgrades/unattended-upgrades.log` |
| Cert renewal dry-run | `sudo certbot renew --dry-run` |
| Reboot after kernel update | `[ -f /var/run/reboot-required ] && sudo reboot` |

## 6. Troubleshooting
| Symptom | Likely cause / fix |
|---|---|
| Ansible `Permission denied (publickey)` | Wrong `ssh_public_key_path`, or cloud-init not finished – wait 30 s and retry |
| certbot fails | DNS not pointing at server, port 80 blocked, or rate limit → use `PK_LE_STAGING=1` |
| 502 Bad Gateway | `systemctl status pkapp`; `journalctl -u pkapp` |
| Locked out of SSH | Hetzner console → rescue/console login; or just `terraform destroy && provision.sh` (it's cattle, not a pet) |
| Browser warning in self-signed mode | Expected; use a domain for a trusted cert |

## 7. Teardown
`terraform -chdir=terraform destroy` – removes server, firewall and key. Stops billing.

## 8. Secret handling / rotation
Rotate the Hetzner token in the console, update `.env`. If a secret was ever committed: revoke it first, then clean history.
