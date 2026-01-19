#!/usr/bin/env bash
set -euo pipefail

VM_NAME="agent-sandbox"
VM_REPO_DIR="/home/lima/repo"
DEST_DIR="${HOME}/dev"
OUT_NAME="lima-repo"
KEEP_REMOTE=1

usage() {
  cat <<'EOF'
Usage: copy-out.sh [--name <vm>] [--repo-dir <path>] [--dest-dir <host-dir>] [--out-name <name>] [--cleanup-remote]

Copies the entire repo out of a Lima VM by:
1) creating a tarball inside the VM
2) copying the tarball to the host
3) extracting it into a folder on the host (replacing any existing folder)

Defaults:
  --dest-dir  "$HOME/dev"
  --out-name  "lima-repo"

Arguments:
  --name          Lima instance name (default: agent-sandbox)
  --repo-dir      Repo path inside VM (default: /home/lima/repo)
  --dest-dir      Host directory to place the extracted repo (default: $HOME/dev)
  --out-name      Output folder name inside dest-dir (default: lima-repo)
  --cleanup-remote Remove the temporary tarball inside the VM (default: keep)

Examples:
  ./copy-out.sh
  ./copy-out.sh --name gemhog
  ./copy-out.sh --dest-dir ~/dev --out-name gemhog-repo
  ./copy-out.sh --repo-dir /home/lima/repo --dest-dir ~/dev
EOF

  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      VM_NAME="$2"; shift 2 ;;
    --repo-dir)
      VM_REPO_DIR="$2"; shift 2 ;;
    --dest-dir)
      DEST_DIR="$2"; shift 2 ;;
    --out-name)
      OUT_NAME="$2"; shift 2 ;;
    --cleanup-remote)
      KEEP_REMOTE=0; shift ;;
    -h|--help)
      usage ;;
    *)
      usage ;;
  esac
done

if ! command -v limactl >/dev/null 2>&1; then
  echo "[host] limactl not found on PATH"
  exit 1
fi

if ! limactl list -q --tty=false | grep -qx "${VM_NAME}"; then
  echo "[host] Lima VM not found: ${VM_NAME}"
  exit 1
fi

mkdir -p "$DEST_DIR"

OUTPUT_DIR="${DEST_DIR%/}/${OUT_NAME}"
TMP_PARENT="$DEST_DIR"

REMOTE_TAR="/tmp/repo-${VM_NAME}-$(date +%s).tar.gz"
LOCAL_TAR="$(mktemp -t repo-${VM_NAME}.XXXXXX.tar.gz)"

echo "[vm] Packing ${VM_REPO_DIR} -> ${REMOTE_TAR}"
limactl shell "$VM_NAME" -- tar -czf "$REMOTE_TAR" -C "$VM_REPO_DIR" .

echo "[host] Copying ${VM_NAME}:${REMOTE_TAR} -> ${LOCAL_TAR}"
limactl copy "${VM_NAME}:${REMOTE_TAR}" "$LOCAL_TAR"

TMP_EXTRACT_DIR="$(mktemp -d "${TMP_PARENT%/}/.${OUT_NAME}.tmp.XXXXXX")"

echo "[host] Extracting -> ${TMP_EXTRACT_DIR}"
tar -xzf "$LOCAL_TAR" -C "$TMP_EXTRACT_DIR"
rm -f "$LOCAL_TAR"

if [ -e "$OUTPUT_DIR" ]; then
  echo "[host] Replacing existing: ${OUTPUT_DIR}"
  rm -rf "$OUTPUT_DIR"
fi

mv "$TMP_EXTRACT_DIR" "$OUTPUT_DIR"

echo "[host] Done: ${OUTPUT_DIR}"

if [ "$KEEP_REMOTE" -eq 0 ]; then
  limactl shell "$VM_NAME" -- rm -f "$REMOTE_TAR"
fi
