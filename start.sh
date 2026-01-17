#!/usr/bin/env bash
set -euo pipefail

VM_NAME="agent-sandbox"
VM_USER="lima"
LIMA_FILE=""
SRC_DIR=""
WORKSPACE_DIR=""
INPUT_TAR="/tmp/input.tar.gz"
STAGING_DIR=""
ENTER_VM=1

usage() {
  echo "Usage: $0 --lima-file <lima.yaml> [--src-dir <repo-dir>] [--ignore-file <path>] [--workspace-dir <path>] [--name <name>] [--no-enter]"
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
    --no-enter)
      ENTER_VM=0; shift ;;
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
  limactl start -y --progress --name "$VM_NAME" "$LIMA_FILE"
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
tar --no-xattrs --no-mac-metadata -czf "$TAR_PATH" -C "$STAGING_DIR" .

# Copy into VM
echo "[host] Copying repository into VM"
limactl copy "$TAR_PATH" "$VM_NAME:$INPUT_TAR"
limactl shell "$VM_NAME" -- rm -rf "${WORKSPACE_DIR}/repo"
limactl shell "$VM_NAME" -- mkdir -p "${WORKSPACE_DIR}/repo"
limactl shell "$VM_NAME" -- tar -xzf "$INPUT_TAR" -C "${WORKSPACE_DIR}/repo"


# Cleanup
rm -rf "$STAGING_DIR" "$TAR_PATH"

# Git identity is provisioned via dotfiles in the VM.

echo "[host] Sandbox ready"

if [ "$ENTER_VM" -eq 1 ]; then
  limactl shell --workdir "${WORKSPACE_DIR}/repo" "$VM_NAME" -- \
    bash -lc 'if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; fi; if command -v zsh >/dev/null 2>&1; then exec zsh -l; fi; exec bash -l'
else
  echo "Enter with: limactl shell $VM_NAME"
fi
