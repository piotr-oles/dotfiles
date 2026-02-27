#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/vibe-kanban"
PORT="42091"

echo "This will install Vibe Kanban into ${INSTALL_DIR}"
echo

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing dependency: $1" >&2
    exit 1
  }
}

need_cmd node
need_cmd npm

mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

# Install package
npm install vibe-kanban@${VERSION}

# Create start.sh
cat > "${INSTALL_DIR}/start.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="\${ROOT_DIR}/.vibe-kanban.pid"
LOG_FILE="\${ROOT_DIR}/vibe-kanban.log"
PORT=${PORT}

if [[ -f "\${PID_FILE}" ]] && kill -0 "\$(cat "\${PID_FILE}")" 2>/dev/null; then
  echo "Vibe Kanban Worker already running (pid \$(cat "\${PID_FILE}"))."
  echo "Open: http://localhost:\${PORT}"
  exit 0
fi

rm -f "\${PID_FILE}"

cd "\${ROOT_DIR}"

if lsof -nP -iTCP:"\${PORT}" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Error: port \${PORT} is already in use:"
  lsof -nP -iTCP:"\${PORT}" -sTCP:LISTEN
  echo
fi

# Start server
nohup env PORT=${PORT} node node_modules/vibe-kanban/bin/cli.js > "\${LOG_FILE}" 2>&1 &

echo \$! > "\${PID_FILE}"

echo
echo "Vibe Kanban Worker started (detached) at: http://localhost:\${PORT}"
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
  echo "Vibe Kanban Worker not running (no pid file)."
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
echo "Installation complete."
echo
echo "  cd ${INSTALL_DIR}"
echo "    ./start.sh (to start in the background)"
echo "    ./logs.sh  (to see logs)"
echo "    ./stop.sh"
