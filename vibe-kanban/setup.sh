#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <workspace-name>"
  exit 1
fi

name="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if the workspaces CLI is installed
if ! command -v workspaces >/dev/null 2>&1; then
  echo "Error: 'workspaces' command not found." >&2
  echo "Install it with: brew update && brew upgrade datadog-workspaces" >&2
  exit 1
fi

# Check if the given workspace exists
if ! workspaces list | grep -qw "${name}"; then
  echo "Error: workspace '${name}' not found." >&2
  echo "Create it with: workspaces create ${name}" >&2
  exit 1
fi

echo "=== Step 1/3: Install Vibe Kanban API on workspace ==="
scp "${SCRIPT_DIR}/install-api.sh" "workspace-${name}:~/install-api.sh"
echo
ssh -t "workspace-${name}" 'bash ~/install-api.sh && rm ~/install-api.sh && ~/vibe-kanban-api/start.sh'

echo
echo "=== Step 2/3: Install Vibe Kanban Worker on workspace ==="
scp "${SCRIPT_DIR}/install-worker.sh" "workspace-${name}:~/install-worker.sh"
echo
ssh -t "workspace-${name}" 'bash ~/install-worker.sh && rm ~/install-worker.sh && ~/vibe-kanban-worker/start.sh'

echo
echo "=== Step 3/3: Forward SSH ports ==="
"${SCRIPT_DIR}/forward-ssh.sh" "${name}"

echo
echo "=== Setup complete ==="
echo "Open: http://localhost:42091"
