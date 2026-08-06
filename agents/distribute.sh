#!/usr/bin/env bash
# distribute.sh: Propagates global standards to harness-specific proxy files.
#
# instructions/GLOBAL.md is the single source of truth
set -euo pipefail

SOURCE="$HOME/dotfiles/agents/instructions/GLOBAL.md"
TARGETS=(
  "$HOME/dotfiles/agents/.claude/CLAUDE.md"
  "$HOME/dotfiles/agents/.pi/agent/AGENTS.md"
)

[[ -s "$SOURCE" ]] || { echo "❌ $SOURCE is missing or empty — refusing to distribute."; exit 1; }

echo "Syncing global standards to harness proxies..."
for target in "${TARGETS[@]}"; do
  if [[ -e "$target" ]] && [[ "$(readlink -f "$target")" == "$(readlink -f "$SOURCE")" ]]; then
    echo "❌ $target resolves to the source! someone fucked  up, remove the symlink first you dodo!"
    exit 1
  fi
  mkdir -p "$(dirname "$target")"
  cp "$SOURCE" "$target"
  echo "  → $target"
done
echo "✅ Parity maintained."
