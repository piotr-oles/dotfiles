#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/vibe-kanban"
PORT="42092"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing dependency: $1" >&2
    exit 1
  }
}

need_cmd git
need_cmd docker
need_cmd openssl

docker compose version >/dev/null 2>&1 || {
  echo "Docker Compose v2 is required (try upgrading Docker)." >&2
  exit 1
}

echo "This will install Vibe Kanban into: ${INSTALL_DIR}"
echo
echo "Create a GitHub OAuth App here:"
echo "  https://github.com/settings/developers"
echo
echo "Use these values:"
echo "  Homepage URL:               http://localhost:${PORT}"
echo "  Authorization callback URL: http://localhost:${PORT}/v1/oauth/github/callback"
echo

mkdir -p "${INSTALL_DIR}"

if [[ -d "${INSTALL_DIR}/.git" ]]; then
  echo "Updating existing repo..."
  git -C "${INSTALL_DIR}" pull --ff-only
else
  echo "Cloning repo..."
  git clone https://github.com/BloopAI/vibe-kanban.git "${INSTALL_DIR}"
fi

ENV_FILE="${INSTALL_DIR}/.env.remote"

if [[ -f "${ENV_FILE}" ]]; then
  echo
  echo ".env.remote already exists. It will NOT be overwritten."
else
  echo
  read -r -p "GITHUB_CLIENT_ID: " GITHUB_CLIENT_ID
  read -r -s -p "GITHUB_SECRET: " GITHUB_SECRET
  echo

  if [[ -z "${GITHUB_CLIENT_ID}" || -z "${GITHUB_SECRET}" ]]; then
    echo "GITHUB_CLIENT_ID and GITHUB_SECRET are required." >&2
    exit 1
  fi

  JWT_SECRET="$(openssl rand -base64 48)"

  cat > "${ENV_FILE}" <<EOF
VIBEKANBAN_REMOTE_JWT_SECRET=${JWT_SECRET}
ELECTRIC_ROLE_PASSWORD=

GITHUB_OAUTH_CLIENT_ID=${GITHUB_CLIENT_ID}
GITHUB_OAUTH_CLIENT_SECRET=${GITHUB_SECRET}

GOOGLE_OAUTH_CLIENT_ID=
GOOGLE_OAUTH_CLIENT_SECRET=

LOOPS_EMAIL_API_KEY=

PUBLIC_BASE_URL=http://localhost:${PORT}
REMOTE_SERVER_PORTS=0.0.0.0:${PORT}:8081
EOF

  echo ".env.remote created."
fi

cat > "${INSTALL_DIR}/start.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

cd "\$(dirname "\${BASH_SOURCE[0]}")/crates/remote"

docker compose \\
  --env-file ../../.env.remote \\
  -f docker-compose.yml \\
  up -d --build

echo
echo "Vibe Kanban is running at: http://localhost:${PORT}"
echo "View logs with: ./logs.sh"
echo "Stop with: ./stop.sh"
EOF

cat > "${INSTALL_DIR}/stop.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

cd "\$(dirname "\${BASH_SOURCE[0]}")/crates/remote"

docker compose \\
  --env-file ../../.env.remote \\
  -f docker-compose.yml \\
  down

echo
echo "Vibe Kanban has been stopped."
EOF

cat > "${INSTALL_DIR}/logs.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

cd "\$(dirname "\${BASH_SOURCE[0]}")/crates/remote"

docker compose \\
  --env-file ../../.env.remote \\
  -f docker-compose.yml \\
  logs -f
EOF

chmod +x "${INSTALL_DIR}/start.sh"
chmod +x "${INSTALL_DIR}/stop.sh"
chmod +x "${INSTALL_DIR}/logs.sh"

echo
echo "Installation complete."
echo
echo "  cd ${INSTALL_DIR}"
echo
echo "Start (background): ./start.sh"
echo "Logs: ./logs.sh"
echo "Stop: ./stop.sh"
echo
echo "Open:"
echo "  http://localhost:${PORT}"
echo
echo "If login fails, confirm your GitHub callback URL is:"
echo "  http://localhost:${PORT}/v1/oauth/github/callback"
