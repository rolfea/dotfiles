#!/usr/bin/env bash
# setup.sh — Deploy and compile generic agent configurations and client adapters.

set -euo pipefail

# Locate the repo from this script rather than assuming ~/dotfiles, so a clone
# anywhere works — and so the whole thing can be exercised against a scratch
# $HOME without writing to the real one.
DOTFILES_AGENTS=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TARGET_AGENTS="$HOME/.agents"

echo "=== Deploying Generic AI Agent Workspaces ==="

# 1. Ensure target agent directories exist
mkdir -p "$TARGET_AGENTS/skills/review-pr/scripts"
mkdir -p "$TARGET_AGENTS/instructions"

# 2. Sync core model-agnostic files to target workspace
echo "Syncing core skills..."
cp "$DOTFILES_AGENTS/core/skills/review-pr/steps.md" "$TARGET_AGENTS/skills/review-pr/steps.md"
cp "$DOTFILES_AGENTS/core/skills/review-pr/scripts/fetch-pr-for-review.sh" "$TARGET_AGENTS/skills/review-pr/scripts/fetch-pr-for-review.sh"

# Ensure all scripts are executable
chmod +x "$TARGET_AGENTS/skills/review-pr/scripts/"*.sh

# 3. Compile and link Claude Code adapter
echo "Deploying Claude Code skills..."
CLAUDE_SKILLS_DIR="$HOME/.claude/skills/review-pr"
mkdir -p "$CLAUDE_SKILLS_DIR"

# Assemble the final SKILL.md by appending core steps to the Claude frontmatter
cat "$DOTFILES_AGENTS/adapters/claude/skills/review-pr/SKILL.md" > "$CLAUDE_SKILLS_DIR/SKILL.md"
echo "" >> "$CLAUDE_SKILLS_DIR/SKILL.md"
cat "$TARGET_AGENTS/skills/review-pr/steps.md" >> "$CLAUDE_SKILLS_DIR/SKILL.md"

# Link scripts folder so any legacy/local references remain fully functional
rm -rf "$CLAUDE_SKILLS_DIR/scripts"
ln -sf "$TARGET_AGENTS/skills/review-pr/scripts" "$CLAUDE_SKILLS_DIR/scripts"

# A fourth step used to recursively delete this repo's agents/.claude/skills,
# left over from before the core/ + adapters/ split. It must not come back:
# ~/.claude is a symlink to agents/.claude, so that directory and the
# CLAUDE_SKILLS_DIR written just above are one and the same — the script
# compiled the skill and then deleted it on the next line. Keeping the
# generated output out of git is handled by agents/.claude/.gitignore, which
# is what the cleanup was actually reaching for.

echo "=== ✅ Setup completed successfully! ==="
echo "  - Core workspace synced to: $TARGET_AGENTS"
echo "  - Compiled Claude skill at: $CLAUDE_SKILLS_DIR/SKILL.md"
