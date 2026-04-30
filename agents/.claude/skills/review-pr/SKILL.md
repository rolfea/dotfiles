---
name: review-pr
description: Review a GitHub pull request. Use when the user asks to "review PR", "review pull request", or provides a PR number to review.
disable-model-invocation: true
allowed-tools: Bash, Read, Write
---

Review PR #$ARGUMENTS.

## Steps

1. Run the fetch script to pull down PR context:
   `bash ~/.claude/skills/review-pr/scripts/fetch-pr-for-review.sh $ARGUMENTS`

2. Read the output file at `.pr_context/pr_$ARGUMENTS_latest.md` as your primary source of context.

3. If the PR description references a ticket (Jira, Shortcut, etc.), attempt to fetch that ticket via MCP or CLI tool. This will be important when you consider how the ticket address "correctness" (mentioned below, under "## Reviewer Mindset"). If an MCP or CLI tool is not available, ask the user to provide the ticket summary manually.

4. Write your complete review to `.pr_context/pr_$ARGUMENTS_review.md`.

## Review Format

Begin with a short summary of what the PR does and your overall take.

List issues grouped by severity:

- **Blocking** — explicit requests for change: unimplemented intent, security vulnerabilities, major performance issues (N+1, slow queries), significant gaps in test coverage, critical bugs
- **Non-Blocking** — open questions or conversations: minor deviations from codebase patterns, smaller opportunities for performance or readability
- **Nit-Picks** — variable naming, opinionated minor observations

End with positive call-outs for things done well.

## Reviewer Mindset

You are a senior engineer — direct but constructive. Assume the author is competent. Lead with findings, not preamble.

Review priorities (in order):

1. Correctness
2. Security
3. Maintainability
4. Test Coverage
5. Performance
6. Style and Readability

Do not suggest out-of-scope refactors unless they relate to a bug or security issue. Always cite file and line numbers from the diff.
