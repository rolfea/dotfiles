# Personal Claude Code Instructions

## Plans
Place any generated plans in the project directory I'm working from (flat at the project root, e.g. `plan.md` or `plan-<ticket>.md`) unless directed otherwise.

## Implementation discipline — red, green, refactor
For every implementation task, follow red → green → refactor:

1. **Red:** confirm there is a failing test that pins the desired behavior. If coverage already exists, run it first and verify it fails in the expected way (or covers the change you are about to make). If coverage is missing, write the failing test *before* any production change.
2. **Green:** make the minimum code change to pass.
3. **Refactor:** clean up with the test still green.

The test is the spec, not the code. This applies even to "pure refactor" work — if existing tests pass unchanged, that *is* the green step. If they fail after a refactor, fix the code, not the test. Plans and task lists for non-trivial work should call this approach out explicitly so it isn't quietly skipped.

## Self-review step
Before reporting work as done or committing a batch of changes, run a self-review pass. Don't rely on CI reviewers or the user to catch things you could have caught yourself.

**Manual checks (all languages):**
- Re-read each changed file for dead imports/exports, duplication with siblings, missing guards that peer code has, compat shims that shouldn't exist
- Check test parity — if one sibling module has a test category, its counterpart should too
- Grep for re-exports or backward-compat patterns in new code

**TypeScript/JavaScript projects:**
- Run `npx fallow audit --base <branch-point>` (e.g. `--base dev` or `--base main`) and address findings before committing:
  - **Dead code:** unused exports, unreferenced files — delete them, don't leave them
  - **Duplication:** clone groups between sibling modules — extract or acknowledge
  - **Complexity:** functions above threshold — consider splitting if the change made it worse

Keep the fallow run lightweight — scope it to changed files via `--base` rather than running a full-project scan. Don't fix pre-existing findings unrelated to your changes unless asked.

## Local test plans — verify the environment against ground truth
Docs drift; the running configuration is authoritative. Before proposing bring-up steps or manual test workflows:

1. **Trust resolved config over prose.** Read ports, hosts, and database names from the actual source of truth (Doppler / `.env` / live config), not from the README or `docker-compose.yml`. When they disagree, the resolved config wins — and flag the discrepancy so the stale doc gets fixed.
2. **Confirm services and schemas actually exist** — never assume "brought up." Check the process is listening, the target databases exist, and required tables are present. A port answering is not the same as the schema being migrated.
3. **State preconditions and dependencies explicitly** in the plan: which env vars must be set, which DBs/tables must exist, which external credentials or connectors are required, and what each workflow *writes to* — especially anything that mutates a shared or real datastore.
4. **Never print secret values while verifying** (see below): mask credentials in connection strings; assert presence and shape, not content.

Net: a test plan should describe the environment as it *is*, with every gap between docs and reality surfaced as an explicit setup step.

## Secrets & environment variables
Never echo, print, or log secrets or environment variables (API keys, tokens, passwords, etc.) to stdout. When a secret is needed — e.g. to call an external API — write a script that consumes the variable directly (via `$ENV_VAR` in a curl header, for instance) without ever surfacing its value in tool output. If the user needs to verify a secret is set, check for non-empty existence (`[ -n "$VAR" ] && echo "set" || echo "unset"`) rather than printing the value.
