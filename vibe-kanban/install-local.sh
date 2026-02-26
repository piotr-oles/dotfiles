#!/usr/bin/env bash
set -euo pipefail

# install-local.sh
# Installs vibe-kanban locally using npx and creates:
#   - start.sh (runs in background)
#   - stop.sh
#   - logs.sh
#
# Local UI port: 42091
# Backend port: 42092

INSTALL_DIR="${HOME}/vibe-kanban-local"
LOCAL_UI_PORT="42091"
BACKEND_PORT="42092"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing dependency: $1" >&2
    exit 1
  }
}

need_cmd node
need_cmd pnpm

mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

# Create start.sh
cat > "${INSTALL_DIR}/start.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="\${ROOT_DIR}/.vibe-kanban.pid"
LOG_FILE="\${ROOT_DIR}/vibe-kanban.log"

LOCAL_UI_PORT="\${LOCAL_UI_PORT:-${LOCAL_UI_PORT}}"
BACKEND_PORT="\${BACKEND_PORT:-${BACKEND_PORT}}"

if [[ -f "\${PID_FILE}" ]] && kill -0 "\$(cat "\${PID_FILE}")" 2>/dev/null; then
  echo "vibe-kanban already running (pid \$(cat "\${PID_FILE}"))."
  echo "Open: http://localhost:\${LOCAL_UI_PORT}"
  exit 0
fi

rm -f "\${PID_FILE}"

cd "\${ROOT_DIR}"

# Run via npx in background
nohup env PORT="\${LOCAL_UI_PORT}" BACKEND_PORT="\${BACKEND_PORT}" \\
  pnpm dlx vibe-kanban > "\${LOG_FILE}" 2>&1 &

echo \$! > "\${PID_FILE}"

echo
echo "vibe-kanban started (detached) at: http://localhost:\${LOCAL_UI_PORT}"
echo "Backend port set to: \${BACKEND_PORT}"
echo "Logs: ./logs.sh"
echo "Stop: ./stop.sh"
EOF

# Create stop.sh
cat > "${INSTALL_DIR}/stop.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="${ROOT_DIR}/.vibe-kanban.pid"

if [[ ! -f "${PID_FILE}" ]]; then
  echo "vibe-kanban not running (no pid file)."
  exit 0
fi

PID="$(cat "${PID_FILE}")"

if kill -0 "${PID}" 2>/dev/null; then
  kill "${PID}"
  echo "Sent SIGTERM to vibe-kanban (pid ${PID})."
else
  echo "Stale pid file (pid ${PID} not running)."
fi

rm -f "${PID_FILE}"
EOF

# Create logs.sh
cat > "${INSTALL_DIR}/logs.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${ROOT_DIR}/vibe-kanban.log"

if [[ ! -f "${LOG_FILE}" ]]; then
  echo "No log file yet at ${LOG_FILE}."
  exit 1
fi

tail -f "${LOG_FILE}"
EOF

chmod +x "${INSTALL_DIR}/start.sh" "${INSTALL_DIR}/stop.sh" "${INSTALL_DIR}/logs.sh"

echo
echo "Local install complete."
echo
echo "To start:"
echo "  cd ${INSTALL_DIR}"
echo "  ./start.sh"
echo
echo "To stop:"
echo "  ./stop.sh"
echo
echo "To view logs:"
echo "  ./logs.sh"
echo
echo "Defaults:"
echo "  Local UI port: ${LOCAL_UI_PORT}"
echo "  Backend port:  ${BACKEND_PORT}"
echo
