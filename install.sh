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

# Install dd-gopls
update-tool dd-gopls

# Configure git
git config --global core.fsmonitor true
git config --global feature.manyFiles true
git config --global index.threads true

for repo in web-ui dd-source; do
  # Configure $repo
  cd $HOME/go/src/github.com/DataDog/$repo

  git maintenance start
  git update-index --index-version 4 && git update-index --really-refresh
  git dd add-branch-prefix piotr.oles
  git dd sync
done

# Install and start Vibe-Kanban
npm config set prefix /usr/local
sudo npm install pm2@latest -g
mkdir -p $HOME/vibe-kanban
cd $HOME/vibe-kanban
npm install vibe-kanban
pm2 start "PORT=42091 HOST=127.0.0.1 node $HOME/vibe-kanban/node_modules/.bin/vibe-kanban" --name vibe-kanban
