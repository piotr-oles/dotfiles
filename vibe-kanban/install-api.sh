#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/vibe-kanban-api"
PORT="42092"

echo "This will install Vibe Kanban API into ${INSTALL_DIR}"
echo

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
  echo "Create a GitHub OAuth App here: https://github.com/settings/developers"
  echo "Use these values:"
  echo "  Homepage URL:               http://localhost:${PORT}"
  echo "  Authorization callback URL: http://localhost:${PORT}/v1/oauth/github/callback"
  echo
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
echo "Vibe Kanban API is running at: http://localhost:${PORT}"
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
echo "Vibe Kanban API has been stopped."
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
echo "API Installation complete."
echo
echo "  cd ${INSTALL_DIR}"
echo "    ./start.sh (to start in the background)"
echo "    ./logs.sh  (to see logs)"
echo "    ./stop.sh"
