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

echo "=== Step 1/3: Checking if workspace ${name} exists ==="

# Check if the given workspace exists
if ! workspaces list | awk -v n="${name}" '$1 == n { found=1 } END { exit !found }'; then
  echo "Error: workspace '${name}' not found." >&2
  echo "" >&2
  workspaces list >&2
  echo "" >&2
  echo "Create it with: workspaces create ${name}" >&2
  exit 1
fi

echo
echo "=== Step 2/3: Install Vibe Kanban on workspace ==="
scp "${SCRIPT_DIR}/install-vibe-kanban.sh" "workspace-${name}:~/install-vibe-kanban.sh"
echo
ssh -t "workspace-${name}" "bash ~/install-vibe-kanban.sh ${name} && rm ~/install-vibe-kanban.sh && ~/vibe-kanban/start.sh"

echo
echo "=== Step 3/3: Forward SSH ports ==="
"${SCRIPT_DIR}/forward-ssh.sh" "${name}"

echo
echo "=== Setup complete ==="
echo "Open: http://localhost:42091"
