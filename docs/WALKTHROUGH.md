# Walkthrough script (record 4–6 min screen capture)

1. **(0:00)** Show repo tree and README architecture; mention tool choices.
2. **(0:40)** Show `.gitignore`, `.env.example`; prove no secrets: `git grep -i token`, `git log --oneline`.
3. **(1:10)** Open `terraform/main.tf` (server, firewall, cloud-init) and explain the non-root user.
4. **(1:50)** Open `roles/base` – explain the `00-hardening.conf` naming trick, UFW ordering, fail2ban, unattended-upgrades.
5. **(2:40)** Open `roles/nginx` – self-signed vs Let's Encrypt branching, two-stage vhost.
6. **(3:10)** Run `./scripts/rebuild_demo.sh` (speed up the wait in editing, keep the timer output visible).
7. **(4:30)** Show smoke-test PASS list, open the URL in browser (padlock/warning), `curl -I http://…` showing 301.
8. **(5:15)** Prove hardening live: `ssh root@IP` refused, `ssh -o PubkeyAuthentication=no deploy@IP` refused, `sudo ufw status`.
9. **(5:45)** Show `docs/timings-*.md` and re-run `ansible-playbook site.yml` to show `changed=0` (idempotence).
