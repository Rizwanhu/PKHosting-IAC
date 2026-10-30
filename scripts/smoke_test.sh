#!/usr/bin/env bash
# Verifies the build. Usage: smoke_test.sh <ip> [admin_user]
set -uo pipefail
IP="${1:?usage: smoke_test.sh <ip> [user]}"
USER_NAME="${2:-deploy}"
HOST="${PK_DOMAIN:-$IP}"
FAIL=0
check() { # name, command...
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "  PASS  $name"; else echo "  FAIL  $name"; FAIL=1; fi
}
CURL_K="-k"; [ -n "${PK_DOMAIN:-}" ] && [ "${PK_LE_STAGING:-1}" != "1" ] && CURL_K=""
SSHO="-o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8"

check "HTTPS returns 200 from app"      bash -c "curl -sf $CURL_K https://$HOST/health | grep -q ok"
check "HTTP redirects to HTTPS (301)"   bash -c "curl -s -o /dev/null -w '%{http_code}' http://$HOST/ | grep -q 301"
check "App proxied (X-Forwarded-Proto)" bash -c "curl -sf $CURL_K https://$HOST/api/info | grep -q https"
check "Root SSH login refused"          bash -c "! ssh $SSHO root@$IP true"
check "Password SSH refused"            bash -c "! ssh $SSHO -o PreferredAuthentications=password -o PubkeyAuthentication=no $USER_NAME@$IP true"
check "Admin key login works"           ssh $SSHO "$USER_NAME@$IP" true
check "UFW active"                      bash -c "ssh $SSHO $USER_NAME@$IP 'sudo ufw status' | grep -q 'Status: active'"
check "fail2ban running"                bash -c "ssh $SSHO $USER_NAME@$IP 'systemctl is-active fail2ban' | grep -q active"
check "Unattended upgrades enabled"     bash -c "ssh $SSHO $USER_NAME@$IP 'cat /etc/apt/apt.conf.d/20auto-upgrades' | grep -q 'Unattended-Upgrade \"1\"'"
check "App not directly exposed (:8000)" bash -c "! curl -s --max-time 4 http://$IP:8000/"
[ $FAIL -eq 0 ] && echo "ALL CHECKS PASSED" || { echo "SOME CHECKS FAILED"; exit 1; }
