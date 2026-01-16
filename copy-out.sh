#!/usr/bin/env bash
set -euo pipefail

VM_NAME=""
SOURCE_DIR=""
DEST_DIR=""

usage() {
  echo "Usage: $0 --name <vm> --dir <path> [--dest <path>]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      VM_NAME="$2"; shift 2 ;;
    --dir)
      SOURCE_DIR="$2"; shift 2 ;;
    --dest)
      DEST_DIR="$2"; shift 2 ;;
    *)
      usage ;;
  esac
done

[[ -z "$VM_NAME" ]] && usage
[[ -z "$SOURCE_DIR" ]] && usage
[[ -z "$DEST_DIR" ]] && DEST_DIR="$(pwd)"

if ! limactl list -q --tty=false | grep -q "^${VM_NAME}$"; then
  echo "[host] Lima VM not found: $VM_NAME"
  exit 1
fi

if [ ! -d "$DEST_DIR" ]; then
  echo "[host] Destination directory not found: $DEST_DIR"
  exit 1
fi

limactl copy "${VM_NAME}:${SOURCE_DIR}" "${DEST_DIR}/"
