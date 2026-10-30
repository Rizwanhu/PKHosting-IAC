#!/usr/bin/env bash
# Destroy the server and rebuild it from scratch, recording timings to docs/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${TF_VAR_hcloud_token:?export TF_VAR_hcloud_token first}"
OUT="$ROOT/docs/timings-$(date +%Y%m%d-%H%M%S).md"

S=$(date +%s)
echo "==> DESTROY"
terraform -chdir="$ROOT/terraform" init -input=false >/dev/null
terraform -chdir="$ROOT/terraform" destroy -auto-approve -input=false
D=$(( $(date +%s) - S ))

echo "==> REBUILD"
"$ROOT/scripts/provision.sh" | tee /tmp/pk_build.log
IFS=, read -r TF SSHW ANS SMK TOT < "$ROOT/.last_build_timings"

{
  echo "# Destroy & rebuild timings ($(date -u '+%Y-%m-%d %H:%M UTC'))"
  echo
  echo "| Stage | Seconds |"
  echo "|---|---|"
  echo "| Terraform destroy | $D |"
  echo "| Terraform apply (create VM) | $TF |"
  echo "| Wait for SSH | $SSHW |"
  echo "| Ansible configure + deploy | $ANS |"
  echo "| Smoke tests | $SMK |"
  echo "| **Total rebuild** | **$TOT** |"
  echo "| **Destroy + rebuild** | **$((D+TOT))** |"
} | tee "$OUT"
echo "Saved: $OUT  (copy the numbers into REPORT.md)"
