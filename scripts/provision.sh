#!/usr/bin/env bash
# Build the server from scratch: terraform apply -> wait for SSH -> ansible -> smoke test.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${TF_VAR_hcloud_token:?export TF_VAR_hcloud_token first (see .env.example)}"

now() { date +%s; }
T0=$(now)

echo "==> [1/4] Terraform apply"
terraform -chdir="$ROOT/terraform" init -input=false >/dev/null
terraform -chdir="$ROOT/terraform" apply -auto-approve -input=false
T1=$(now)

IP=$(terraform -chdir="$ROOT/terraform" output -raw ipv4)
USER_NAME=$(terraform -chdir="$ROOT/terraform" output -raw admin_user)
printf "[web]\nserver ansible_host=%s ansible_user=%s\n" "$IP" "$USER_NAME" > "$ROOT/ansible/inventory.ini"
ssh-keygen -R "$IP" >/dev/null 2>&1 || true

echo "==> [2/4] Waiting for SSH on $IP"
for i in $(seq 1 60); do
  if ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -o BatchMode=yes \
       "$USER_NAME@$IP" true 2>/dev/null; then break; fi
  sleep 5
  [ "$i" -eq 60 ] && { echo "SSH never came up"; exit 1; }
done
T2=$(now)

echo "==> [3/4] Ansible configuration"
( cd "$ROOT/ansible" && ansible-galaxy collection install -r requirements.yml >/dev/null \
  && ansible-playbook site.yml )
T3=$(now)

echo "==> [4/4] Smoke tests"
"$ROOT/scripts/smoke_test.sh" "$IP"
T4=$(now)

cat <<OUT

---------------- TIMINGS ----------------
Terraform apply (VM created) : $((T1-T0)) s
Wait for SSH (boot)          : $((T2-T1)) s
Ansible (config + deploy)    : $((T3-T2)) s
Smoke tests                  : $((T4-T3)) s
TOTAL build                  : $((T4-T0)) s
-----------------------------------------
URL: https://${PK_DOMAIN:-$IP}/
OUT
echo "$((T1-T0)),$((T2-T1)),$((T3-T2)),$((T4-T3)),$((T4-T0))" > "$ROOT/.last_build_timings"
