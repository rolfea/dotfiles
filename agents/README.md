# Dotfiles AI Agents Architecture

This directory holds a generic, model-agnostic system for sharing AI agent instructions, custom developer personas, and execution "skills" across multiple AI clients (e.g., Claude Code, Claude Desktop, Cursor, VS Code Copilot, or Gemini/Antigravity).

By separating core rules and scripts from model-specific headers, you can maintain a **single source of truth** in your dotfiles and deploy customized adapters to each client.

---

## 📂 Directory Structure

```text
agents/
├── core/                  # MODEL-AGNOSTIC CORE (Single Source of Truth)
│   ├── instructions/      # Raw markdown guidelines, rules, and personas
│   └── skills/            # Procedural workflows
│       └── review-pr/
│           ├── steps.md   # Core markdown instructions (no metadata/frontmatter)
│           └── scripts/   # Standard executable terminal scripts
│
├── adapters/              # CLIENT-SPECIFIC WRAPPERS & METADATA
│   └── claude/            # Files configured for Anthropic's Claude Code
│       └── skills/
│           └── review-pr/
│               └── SKILL.md  # Client-specific YAML frontmatter header
│
├── setup.sh               # Compilation, symlinking, and deployment engine
└── README.md              # This documentation
```

---

## ⚙️ How It Works (The Core + Adapter Pattern)

### 1. The Core (`core/`)
All instructions, persona files, and execution scripts are kept completely independent of any specific AI tool. 
* Procedural guides are written in standard markdown (`steps.md`).
* Helper scripts are kept under the `scripts/` directories.

### 2. Client Adapters (`adapters/`)
Different clients expect dynamic configs (e.g., Claude Code expects a YAML frontmatter header, while Cursor expects a concatenated `.cursorrules` file). 
* Adapters hold client-specific files (like a metadata-only `SKILL.md`).
* When compiled, the compiler merges the adapter metadata with the core rules.

### 3. The Target Workspace (`~/.agents/`)
Instead of symlinking directly to your dotfiles directory (which can break due to relative path changes between work/personal computers or trigger agent sandboxing blocks), all core code is synchronized to a standardized intermediate path: **`~/.agents/`**. 
All custom scripts use `~/.agents/` as their absolute path reference, making them 100% portable.

---

## 🚀 Usage

To deploy or compile updates to your AI systems, run the setup script:

```bash
cd ~/dotfiles/agents
bash ./setup.sh
```

This will automatically:
1. Sync all core model-agnostic guidelines and scripts to `~/.agents/`.
2. Ensure all scripts are executable (`chmod +x`).
3. Compile `~/.claude/skills/review-pr/SKILL.md` by combining the Claude frontmatter header with the core instructions.
4. Establish backward-compatible symlinks.
5. Keep your local `dotfiles` git tree perfectly clean.

---

## 🛠️ Adding New Skills or Personas

### To Add a New Core Skill:
1. Create `core/skills/<my-skill>/steps.md`.
2. Add any associated executables to `core/skills/<my-skill>/scripts/`.
3. If using Claude Code, create `adapters/claude/skills/<my-skill>/SKILL.md` containing the required YAML header:
   ```yaml
   ---
   name: <my-skill>
   description: <When to use the skill>
   disable-model-invocation: true
   allowed-tools: Bash, Read, Write
   ---
   ```
4. Add the compilation step to `setup.sh`:
   ```bash
   # In setup.sh:
   mkdir -p "$HOME/.claude/skills/<my-skill>"
   cat "$DOTFILES_AGENTS/adapters/claude/skills/<my-skill>/SKILL.md" \
       $'\n' \
       "$TARGET_AGENTS/skills/<my-skill>/steps.md" \
       > "$HOME/.claude/skills/<my-skill>/SKILL.md"
   ```
