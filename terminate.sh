#!/usr/bin/env bash
set -euo pipefail

VM_NAME="agent-sandbox"

usage() {
  echo "Usage: $0 [--name <name>]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      VM_NAME="$2"; shift 2 ;;
    *)
      usage ;;
  esac
done

if limactl list -q --tty=false | grep -q "^${VM_NAME}$"; then
  echo "[host] Stopping Lima VM: $VM_NAME"
  limactl stop "$VM_NAME"
  echo "[host] Deleting Lima VM: $VM_NAME"
  limactl delete "$VM_NAME"
else
  echo "[host] Lima VM not found: $VM_NAME"
fi
