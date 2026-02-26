#!/usr/bin/env bash
# ensure you set the executable bit on the file with `chmod u+x install.sh`

# If you remove the .example extension from the file, once your workspace is created and the contents of this
# repo are copied into it, this script will execute.  This will happen in place of the default behavior of the workspace system,
# which is to symlink the dotfiles copied from this repo to the home directory in the workspace.
#
# Why would one use this file in stead of relying upon the default behavior?
#
# Using this file gives you a bit more control over what happens.
# If you want to do something complex in your workspace setup, you can do that here.
# Also, you can use this file to automatically install a certain tool in your workspace, such as vim.
#
# Just in case you still want the default behavior of symlinking the dotfiles to the root,
# we've included a block of code below for your convenience that does just that.

set -euo pipefail

DOTFILES_PATH="$HOME/dotfiles"

# Symlink dotfiles to the root within your workspace
find $DOTFILES_PATH -type f -path "$DOTFILES_PATH/.*" |
while read df; do
  link=${df/$DOTFILES_PATH/$HOME}
  mkdir -p "$(dirname "$link")"
  ln -sf "$df" "$link"
done

# Install ZED
curl -f https://zed.dev/install.sh | sh

# Install tools
update-tool dd-gopls ddtool bzl git-dd rapid

# Configure git
git config --global core.fsmonitor true
git config --global feature.manyFiles true
git config --global index.threads true
git config --global push.autoSetupRemote true

# Install and start Vibe-Kanban
mkdir -p $HOME/vibe-kanban
cd $HOME/vibe-kanban
npm install vibe-kanban
cat << 'EOF' > $HOME/vibe-kanban/run.sh
#!/usr/bin/env sh
delay=1
max=60
while true; do
  HOST=127.0.0.1 PORT=42091 node $HOME/vibe-kanban/node_modules/.bin/vibe-kanban
  code=$?
  echo "exit=$code" >&2
  sleep "$delay"
  if [ "$delay" -lt "$max" ]; then
    delay=$(( delay * 2 ))
    if [ "$delay" -gt "$max" ]; then
      delay="$max"
    fi
  fi
done
EOF
chmod +x $HOME/vibe-kanban/run.sh
touch $HOME/vibe-kanban/log.log
nohup $HOME/vibe-kanban/run.sh > $HOME/vibe-kanban/log.log 2>&1 &

echo "Vibe-Kanban started, listening on http://127.0.0.1:42091"
echo "You can access logs at ~/vibe-kanban/log.log"

for repo in web-ui dd-source; do
  # Configure $repo
  cd $HOME/go/src/github.com/DataDog/$repo

  git maintenance start
  git update-index --index-version 4 && git update-index --really-refresh
  git dd add-branch-prefix piotr.oles
  git dd sync
  git config remote.origin.tagOpt --no-tags
  git config remote.origin.prune true
done
