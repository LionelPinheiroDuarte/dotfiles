#!/usr/bin/env bash
#
# install-git-hooks.sh — install the versioned post-commit hook.
#
# This machine uses a global `core.hooksPath` (default ~/.git-hooks), so a
# single hook there covers every repo — existing and future clones — with no
# per-repo setup and no git template needed. We just symlink our versioned
# hook into that directory.
#
# Idempotent: safe to re-run after editing the hook.

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/repos/github/dotfiles}"
HOOK_SRC="$DOTFILES/git/hooks/post-commit"

[ -f "$HOOK_SRC" ] || { echo "error: hook not found at $HOOK_SRC" >&2; exit 1; }
chmod +x "$HOOK_SRC"

# Resolve the global hooks dir, defaulting to ~/.git-hooks and enabling it if
# it isn't configured yet.
hooks_dir=$(git config --global --get core.hooksPath || true)
if [ -z "$hooks_dir" ]; then
  hooks_dir="$HOME/.git-hooks"
  git config --global core.hooksPath "$hooks_dir"
  echo "config   : set core.hooksPath = $hooks_dir"
fi
hooks_dir="${hooks_dir/#\~/$HOME}"   # expand a leading ~ if present
mkdir -p "$hooks_dir"

dest="$hooks_dir/post-commit"
# Back up a pre-existing real hook once, then symlink.
if [ -e "$dest" ] && [ ! -L "$dest" ]; then
  mv "$dest" "$dest.bak.$(date +%s)"
  echo "backup   : $dest -> $dest.bak.*"
fi
ln -sfn "$HOOK_SRC" "$dest"

echo "linked   : $dest -> $HOOK_SRC"
echo "done — the hook now runs for every repo via core.hooksPath."
