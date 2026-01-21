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

# Copy repository into VM
COPY_IN_ARGS=(
  --src-dir "$SRC_DIR"
  --workspace-dir "$WORKSPACE_DIR"
  --name "$VM_NAME"
)

if [ -n "${IGNORE_FILE_OVERRIDE:-}" ]; then
  COPY_IN_ARGS+=(--ignore-file "$IGNORE_FILE_OVERRIDE")
fi

"$(dirname "$0")/copy-in.sh" "${COPY_IN_ARGS[@]}"

# Git identity is provisioned via dotfiles in the VM.

echo "[host] Sandbox ready"

if [ "$ENTER_VM" -eq 1 ]; then
  limactl shell --workdir "${WORKSPACE_DIR}/repo" "$VM_NAME" -- \
    bash -lc 'if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; fi; if command -v zsh >/dev/null 2>&1; then exec zsh -l; fi; exec bash -l'
else
  echo "Enter with: limactl shell $VM_NAME"
fi
