#!/usr/bin/env bash
# setup.sh — Deploy and compile generic agent configurations and client adapters.

set -euo pipefail

DOTFILES_AGENTS="$HOME/dotfiles/agents"
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

# 4. Clean up old dotfiles-internal .claude skills (since we shifted to /core and /adapters)
echo "Cleaning up local repository skill duplicates..."
rm -rf "$DOTFILES_AGENTS/.claude/skills"

echo "=== ✅ Setup completed successfully! ==="
echo "  - Core workspace synced to: $TARGET_AGENTS"
echo "  - Compiled Claude skill at: $CLAUDE_SKILLS_DIR/SKILL.md"
