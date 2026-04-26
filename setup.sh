#!/usr/bin/env bash
# post-create.sh — run once after the dev container is created.
# Builds the retaliq CLI binary and installs bash completion.

set -euo pipefail

WORKSPACE_ROOT="$(pwd)"
CMD_DIR="${WORKSPACE_ROOT}/cmd"
BINARY_NAME="retaliq"
BINARY_PATH="${CMD_DIR}/${BINARY_NAME}"
INSTALL_PATH="/usr/local/bin/${BINARY_NAME}"
COMPLETION_DIR="${HOME}/.local/share/bash-completion/completions"
COMPLETION_FILE="${COMPLETION_DIR}/${BINARY_NAME}"
BASHRC="${HOME}/.bashrc"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   retaliq CLI — build & completion setup     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 0. Bootstrap services/.env from example if missing ───────────────────────
SERVICES_ENV="${WORKSPACE_ROOT}/services/.env"
SERVICES_ENV_EXAMPLE="${WORKSPACE_ROOT}/services/.env.example"
if [ ! -f "${SERVICES_ENV}" ]; then
  if [ -f "${SERVICES_ENV_EXAMPLE}" ]; then
    cp "${SERVICES_ENV_EXAMPLE}" "${SERVICES_ENV}"
    echo "  ✔ Created services/.env from .env.example"
  else
    echo "  ⚠ services/.env.example not found — skipping"
  fi
else
  echo "  ✔ services/.env already exists — skipping"
fi
echo ""

# ── 1. Build the binary (skip if pre-built binary already exists) ─────────────
if [ -f "${BINARY_PATH}" ]; then
  echo "► Pre-built binary found at ${BINARY_PATH} — skipping build."
else
  echo "► Building retaliq binary..."
  cd "${CMD_DIR}"
  go build -o "${BINARY_PATH}" .
  echo "  ✔ Binary: ${BINARY_PATH}"
fi

# ── 2. Install to /usr/local/bin so it is on PATH system-wide ─────────────────
echo "► Installing to ${INSTALL_PATH}..."
sudo cp "${BINARY_PATH}" "${INSTALL_PATH}"
sudo chmod +x "${INSTALL_PATH}"
echo "  ✔ Installed: ${INSTALL_PATH}"

# ── 3. Symlink at workspace root for quick access ─────────────────────────────
# SYMLINK="${WORKSPACE_ROOT}/${BINARY_NAME}"
# if [ -L "${SYMLINK}" ] || [ -f "${SYMLINK}" ]; then
#   rm -f "${SYMLINK}"
# fi
# ln -s "${BINARY_PATH}" "${SYMLINK}"
# echo "  ✔ Symlink: ${SYMLINK} → ${BINARY_PATH}"

# ── 4. Generate and install bash completion ───────────────────────────────────
echo "► Generating bash completion..."
mkdir -p "${COMPLETION_DIR}"
"${INSTALL_PATH}" completion bash > "${COMPLETION_FILE}"
echo "  ✔ Completion script: ${COMPLETION_FILE}"

# Ensure the completion directory is sourced from ~/.bashrc
COMPLETION_SOURCE_BLOCK='
# retaliq bash completion
if [ -d "${HOME}/.local/share/bash-completion/completions" ]; then
  for f in "${HOME}/.local/share/bash-completion/completions"/*; do
    [ -r "$f" ] && source "$f"
  done
fi'

if ! grep -q "retaliq bash completion" "${BASHRC}" 2>/dev/null; then
  echo "${COMPLETION_SOURCE_BLOCK}" >> "${BASHRC}"
  echo "  ✔ Completion sourced in ${BASHRC}"
else
  echo "  (completion block already present in ${BASHRC})"
fi

# Also add to /etc/bash_completion.d/ for system-wide availability
if [ -d "/etc/bash_completion.d" ]; then
  sudo cp "${COMPLETION_FILE}" "/etc/bash_completion.d/${BINARY_NAME}"
  echo "  ✔ System completion: /etc/bash_completion.d/${BINARY_NAME}"
fi

# ── 5. Verify ─────────────────────────────────────────────────────────────────
echo ""
echo "► Verifying installation..."
"${INSTALL_PATH}" --help 2>&1 | awk 'NR<=5'
echo ""
echo "✔  Done. Run 'retaliq --help' in a new terminal (or 'source ~/.bashrc')."
echo ""
