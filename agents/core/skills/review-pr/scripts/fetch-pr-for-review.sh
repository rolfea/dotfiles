#!/usr/bin/env bash
# fetch-pr-for-review.sh — Pull down PR context for AI agent review
# Usage: fetch-pr-for-review.sh <PR_NUMBER> [OWNER/REPO]
# If OWNER/REPO is omitted, defaults to the repo in the current directory.

set -euo pipefail

# ── Helpers ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[fetch_pr]${NC} $*"; }
warn() { echo -e "${YELLOW}[fetch_pr]${NC} $*"; }
die()  { echo -e "${RED}[fetch_pr] ERROR:${NC} $*" >&2; exit 1; }

# ── Check dependencies ────────────────────────────────────────────────────────

if ! command -v gh &>/dev/null; then
  echo -e "${RED}[fetch_pr] GitHub CLI (gh) is not installed.${NC}"
  echo ""
  echo "  Install it with one of the following:"
  echo "    macOS:   brew install gh"
  echo "    Linux:   https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
  echo "    Windows: winget install --id GitHub.cli"
  echo ""
  echo "  Then authenticate with: gh auth login"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  die "GitHub CLI is installed but you are not authenticated. Run: gh auth login"
fi

if ! command -v jq &>/dev/null; then
  echo -e "${RED}[fetch_pr] jq is not installed.${NC}"
  echo ""
  echo "  Install it with one of the following:"
  echo "    macOS:   brew install jq"
  echo "    Linux:   apt install jq  /  dnf install jq  /  pacman -S jq"
  echo "    Windows: winget install jqlang.jq  /  choco install jq"
  exit 1
fi

# ── Args ──────────────────────────────────────────────────────────────────────

PR_NUMBER="${1:-}"

if [[ -z "$PR_NUMBER" ]]; then
  die "Usage: $0 <PR_NUMBER|PR_URL> [OWNER/REPO]"
fi

# Accept either a bare PR number or a GitHub PR URL
# (e.g. https://github.com/OWNER/REPO/pull/1234[/files]).
PR_NUMBER="${PR_NUMBER##*/pull/}"   # strip everything up to and including /pull/
PR_NUMBER="${PR_NUMBER%%[!0-9]*}"   # keep only the leading digits

if [[ -z "$PR_NUMBER" ]]; then
  die "Could not extract a PR number from input: '${1}'"
fi

if [[ -n "${2:-}" ]]; then
  REPO_LABEL="$2"
else
  REPO_LABEL=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
fi
REPO_FLAG=(--repo "$REPO_LABEL")

# ── Output file ───────────────────────────────────────────────────────────────

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="${PR_CONTEXT_DIR:-$HOME/.agents/pr-reviews}"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/pr_${PR_NUMBER}_${TIMESTAMP}.md"

info "Fetching PR #${PR_NUMBER} from ${REPO_LABEL}..."

# ── Fetch data ────────────────────────────────────────────────────────────────

# Core PR metadata
PR_JSON=$(gh pr view "$PR_NUMBER" "${REPO_FLAG[@]}" \
  --json number,title,state,author,baseRefName,headRefName,createdAt,updatedAt,body,labels,reviewRequests,reviews,assignees,url)

PR_TITLE=$(     echo "$PR_JSON" | jq -r '.title')
PR_STATE=$(     echo "$PR_JSON" | jq -r '.state')
PR_AUTHOR=$(    echo "$PR_JSON" | jq -r '.author.login')
PR_BASE=$(      echo "$PR_JSON" | jq -r '.baseRefName')
PR_HEAD=$(      echo "$PR_JSON" | jq -r '.headRefName')
PR_CREATED=$(   echo "$PR_JSON" | jq -r '.createdAt')
PR_UPDATED=$(   echo "$PR_JSON" | jq -r '.updatedAt')
PR_URL=$(       echo "$PR_JSON" | jq -r '.url')
PR_BODY=$(      echo "$PR_JSON" | jq -r '.body // "_No description provided._"')
PR_LABELS=$(    echo "$PR_JSON" | jq -r '[.labels[].name] | if length == 0 then "none" else join(", ") end')
PR_REVIEWERS=$( echo "$PR_JSON" | jq -r '[.reviewRequests[] | (.login // .name)] | if length == 0 then "none" else join(", ") end')

# Diff
info "Fetching diff..."
PR_DIFF=$(gh pr diff "$PR_NUMBER" "${REPO_FLAG[@]}" 2>/dev/null || echo "_Diff unavailable._")

# Changed files summary
info "Fetching changed files list..."
PR_FILES=$(gh api \
  "repos/{owner}/{repo}/pulls/${PR_NUMBER}/files" \
  "${REPO_FLAG[@]}" \
  --paginate \
  --jq '.[] | "\(.status | ascii_upcase)\t\(.filename)\t(+\(.additions) / -\(.deletions))"' \
  2>/dev/null || echo "_Could not fetch file list._")

# Submitted reviews (approved / changes requested / commented)
info "Fetching submitted reviews..."
PR_REVIEWS=$(gh api \
  "repos/{owner}/{repo}/pulls/${PR_NUMBER}/reviews" \
  "${REPO_FLAG[@]}" \
  --paginate \
  --jq '
    if length == 0 then "_No submitted reviews._"
    else .[] | "**\(.user.login)** — \(.state) at \(.submitted_at):\n\(.body // "_No review body._")\n"
    end
  ' \
  2>/dev/null || echo "_Could not fetch reviews._")

# Inline review comments
info "Fetching inline review comments..."
PR_REVIEW_COMMENTS=$(gh api \
  "repos/{owner}/{repo}/pulls/${PR_NUMBER}/comments" \
  "${REPO_FLAG[@]}" \
  --paginate \
  --jq '
    if length == 0 then "_No inline review comments._"
    else .[] | "**\(.user.login)** on `\(.path)` (line \(.line // .original_line // "?")):\n> \(.body)\n"
    end
  ' \
  2>/dev/null || echo "_Could not fetch review comments._")

# General PR discussion comments
info "Fetching discussion comments..."
PR_ISSUE_COMMENTS=$(gh api \
  "repos/{owner}/{repo}/issues/${PR_NUMBER}/comments" \
  "${REPO_FLAG[@]}" \
  --paginate \
  --jq '
    if length == 0 then "_No discussion comments._"
    else .[] | "**\(.user.login)** at \(.created_at):\n\(.body)\n"
    end
  ' \
  2>/dev/null || echo "_Could not fetch discussion comments._")

# CI / check status
info "Fetching CI check status..."
PR_CHECKS=$(gh pr checks "$PR_NUMBER" "${REPO_FLAG[@]}" 2>/dev/null || echo "_Check status unavailable._")

# Commits
info "Fetching commits..."
PR_COMMITS=$(gh pr view "$PR_NUMBER" "${REPO_FLAG[@]}" \
  --json commits \
  --jq '[.commits[] | "- \(.messageHeadline) (`\(.oid[:7])`)"] | join("\n")' \
  2>/dev/null || echo "_Could not fetch commits._")

# ── Write output ──────────────────────────────────────────────────────────────

cat > "$OUTPUT_FILE" <<MARKDOWN
# PR #${PR_NUMBER} — ${PR_TITLE}

> Generated by fetch_pr.sh on $(date)

---

## Metadata

| Field                   | Value |
|-------------------------|-------|
| **URL**                 | ${PR_URL} |
| **State**               | ${PR_STATE} |
| **Author**              | ${PR_AUTHOR} |
| **Base ← Head**         | \`${PR_BASE}\` ← \`${PR_HEAD}\` |
| **Labels**              | ${PR_LABELS} |
| **Reviewers requested** | ${PR_REVIEWERS} |
| **Created**             | ${PR_CREATED} |
| **Last updated**        | ${PR_UPDATED} |

---

## Description

${PR_BODY}

---

## Changed Files

\`\`\`
${PR_FILES}
\`\`\`

---

## CI / Check Status

\`\`\`
${PR_CHECKS}
\`\`\`

---

## Commits

${PR_COMMITS}

---

## Diff

\`\`\`diff
${PR_DIFF}
\`\`\`

---

## Submitted Reviews

${PR_REVIEWS}

---

## Inline Review Comments

${PR_REVIEW_COMMENTS}

---

## Discussion / General Comments

${PR_ISSUE_COMMENTS}

---

_End of PR context. File generated at: ${OUTPUT_FILE}_
MARKDOWN

LATEST_FILE="$OUTPUT_DIR/pr_${PR_NUMBER}_latest.md"
cp "$OUTPUT_FILE" "$LATEST_FILE"

FILE_SIZE=$(wc -c < "$OUTPUT_FILE")
FILE_LINES=$(wc -l < "$OUTPUT_FILE")
info "Done! Context written to: ${OUTPUT_FILE}"
info "Stable path:              ${LATEST_FILE}"
info "File size: $(( FILE_SIZE / 1024 ))KB / ${FILE_LINES} lines"
if (( FILE_SIZE > 512000 )); then
  warn "Output file is large (>500KB). Large diffs may exceed context limits."
  warn "Consider reviewing specific files: gh pr diff ${PR_NUMBER} -- <path>"
fi
echo ""
echo "  To review, run your AI agent from any project and say:"
echo "    \"Review PR #${PR_NUMBER}\" — context is at ${LATEST_FILE}"
