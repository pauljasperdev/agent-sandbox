#!/usr/bin/env bash
set -euo pipefail

VM_NAME="agent-sandbox"
VM_USER="lima"
SRC_DIR=""
WORKSPACE_DIR=""
INPUT_TAR="/tmp/input.tar.gz"

usage() {
  echo "Usage: $0 [--src-dir <repo-dir>] [--ignore-file <path>] [--workspace-dir <path>] [--name <name>]"
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --src-dir)
      SRC_DIR="$2"; shift 2 ;;
    --ignore-file)
      IGNORE_FILE_OVERRIDE="$2"; shift 2 ;;
    --workspace-dir)
      WORKSPACE_DIR="$2"; shift 2 ;;
    --name)
      VM_NAME="$2"; shift 2 ;;
    *)
      usage ;;
  esac
done

[[ -z "$SRC_DIR" ]] && SRC_DIR="$(pwd)"
[[ -z "$WORKSPACE_DIR" ]] && WORKSPACE_DIR="/home/${VM_USER}"

if ! command -v limactl >/dev/null 2>&1; then
  echo "Missing limactl on host"
  exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
  echo "Missing source directory: $SRC_DIR"
  exit 1
fi

if [ -n "${IGNORE_FILE_OVERRIDE:-}" ] && [ ! -f "$IGNORE_FILE_OVERRIDE" ]; then
  echo "Missing ignore file: $IGNORE_FILE_OVERRIDE"
  exit 1
fi

if ! limactl list -q --tty=false | grep -q "^${VM_NAME}$"; then
  echo "Missing Lima VM: $VM_NAME"
  echo "Create it with: ./start.sh --lima-file ./lima.yaml"
  exit 1
fi

# Stage repo (copy everything by default)
STAGING_DIR="$(mktemp -d)"

echo "[host] Staging repository"
if [ -n "${IGNORE_FILE_OVERRIDE:-}" ]; then
  rsync -a --delete --exclude-from="$IGNORE_FILE_OVERRIDE" "$SRC_DIR/" "$STAGING_DIR/"
else
  rsync -a --delete "$SRC_DIR/" "$STAGING_DIR/"
fi

# Package staged repo
echo "[host] Packaging repository"
TAR_PATH="$(mktemp)"
tar --no-xattrs --no-mac-metadata -czf "$TAR_PATH" -C "$STAGING_DIR" .

# Copy into VM
echo "[host] Copying repository into VM"
limactl copy "$TAR_PATH" "$VM_NAME:$INPUT_TAR"
limactl shell "$VM_NAME" -- rm -rf "${WORKSPACE_DIR}/repo"
limactl shell "$VM_NAME" -- mkdir -p "${WORKSPACE_DIR}/repo"
limactl shell "$VM_NAME" -- tar -xzf "$INPUT_TAR" -C "${WORKSPACE_DIR}/repo"

# Cleanup
rm -rf "$STAGING_DIR" "$TAR_PATH"
