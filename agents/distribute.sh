#!/usr/bin/env bash
# distribute.sh: Propagates global standards to harness-specific proxy files.

SOURCE="$HOME/dotfiles/agents/instructions/GLOBAL.md"
CLAUDEMD="$HOME/dotfiles/agents/.claude/CLAUDE.md"
PIAGENTS="$HOME/dotfiles/agents/.pi/agent/AGENTS.md"

echo "Syncing global standards to harness proxies..."
cat "$SOURCE" > "$CLAUDEMD"
cat "$SOURCE" > "$PIAGENTS"
echo "✅ Parity maintained."
