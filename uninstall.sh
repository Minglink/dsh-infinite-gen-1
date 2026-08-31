#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="dsh-infinite-gen-3"
DSH_ROOT="${HOME}/.dsh"
DEST_DIR="${DSH_ROOT}/plugins/${PLUGIN_NAME}"

echo "==> 卸载 ${PLUGIN_NAME}..."
rm -rf "${DEST_DIR}"
echo "    [OK] 已删除 ${DEST_DIR}"
