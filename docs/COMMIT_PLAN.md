# Suggested real commit history
Make these as genuine, separate commits while you test each part (don't squash into one):

1. `chore: repo skeleton, .gitignore, .env.example`
2. `feat(terraform): server, ssh key, cloud firewall`
3. `feat(terraform): cloud-init creates non-root admin user`
4. `feat(ansible): base role - packages, timezone`
5. `feat(ansible): SSH hardening drop-in`
6. `feat(ansible): UFW + fail2ban`
7. `feat(ansible): unattended security upgrades`
8. `feat(app): Flask sample app + gunicorn systemd unit`
9. `feat(nginx): reverse proxy + self-signed TLS`
10. `feat(nginx): Let's Encrypt via certbot webroot + renewal hook`
11. `feat(scripts): provision + smoke tests`
12. `feat(scripts): rebuild demo with timings`
13. `ci: terraform validate, ansible-lint, shellcheck`
14. `docs: README, runbook, checklist`
15. `docs: add measured timings and final report`
Also commit genuine bug fixes you hit (e.g. `fix(ssh): rename drop-in to 00- so it wins over cloud-init`).
