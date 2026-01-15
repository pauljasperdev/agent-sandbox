#!/usr/bin/env bash
set -euo pipefail

VM_NAME="agent-sandbox"
VM_USER="ubuntu"
LIMA_FILE=""
SRC_DIR=""
WORKSPACE_DIR=""
INPUT_TAR="/tmp/input.tar.gz"
STAGING_DIR=""

usage() {
  echo "Usage: $0 --lima-file <lima.yaml> [--src-dir <repo-dir>] [--ignore-file <path>] [--workspace-dir <path>] [--name <name>]"
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --lima-file)
      LIMA_FILE="$2"; shift 2 ;;
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

[[ -z "$LIMA_FILE" ]] && usage
[[ -z "$SRC_DIR" ]] && SRC_DIR="$(pwd)"
[[ -z "$WORKSPACE_DIR" ]] && WORKSPACE_DIR="/home/${VM_USER}"

if [ ! -f "$LIMA_FILE" ]; then
  echo "Missing lima file: $LIMA_FILE"
  exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
  echo "Missing source directory: $SRC_DIR"
  exit 1
fi

# Start VM if not running
if ! limactl list -q --tty=false | grep -q "^${VM_NAME}$"; then
  echo "[host] Creating Lima VM: $VM_NAME"
  limactl start --name "$VM_NAME" "$LIMA_FILE"
else
  echo "[host] Lima VM already exists: $VM_NAME"
fi

# Stage repo respecting ignore rules
STAGING_DIR="$(mktemp -d)"
IGNORE_FILE=""

if [ -n "${IGNORE_FILE_OVERRIDE:-}" ]; then
  IGNORE_FILE="$IGNORE_FILE_OVERRIDE"
elif [ -f "$SRC_DIR/.limaignore" ]; then
  IGNORE_FILE="$SRC_DIR/.limaignore"
elif [ -f "$SRC_DIR/.gitignore" ]; then
  IGNORE_FILE="$SRC_DIR/.gitignore"
fi

echo "[host] Staging repository"
if [ -n "$IGNORE_FILE" ]; then
  rsync -a --delete --exclude-from="$IGNORE_FILE" "$SRC_DIR/" "$STAGING_DIR/"
else
  rsync -a --delete "$SRC_DIR/" "$STAGING_DIR/"
fi

# Package staged repo
echo "[host] Packaging repository"
TAR_PATH="$(mktemp)"
tar -czf "$TAR_PATH" -C "$STAGING_DIR" .

# Copy into VM
echo "[host] Copying repository into VM"
limactl copy "$TAR_PATH" "$VM_NAME:$INPUT_TAR"
limactl shell "$VM_NAME" -- rm -rf "${WORKSPACE_DIR}/repo"
limactl shell "$VM_NAME" -- mkdir -p "${WORKSPACE_DIR}/repo"
limactl shell "$VM_NAME" -- tar -xzf "$INPUT_TAR" -C "${WORKSPACE_DIR}/repo"

# Cleanup
rm -rf "$STAGING_DIR" "$TAR_PATH"

# Copy Git identity config if present
HOST_GIT_CONFIG="$HOME/.config/git/config"
if [ -f "$HOST_GIT_CONFIG" ]; then
  echo "[host] Copying git config for commit identity"
  limactl shell "$VM_NAME" -- mkdir -p "/home/${VM_USER}/.config/git"
  limactl copy "$HOST_GIT_CONFIG" "$VM_NAME:/home/${VM_USER}/.config/git/config"
else
  echo "[host] No git config found at ~/.config/git/config (skipping)"
fi

echo "[host] Sandbox ready"
echo "Enter with: limactl shell $VM_NAME"
