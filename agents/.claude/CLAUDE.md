# Personal Claude Code Instructions

## Plans
Place any generated plans in the project directory I'm working from (flat at the project root, e.g. `plan.md` or `plan-<ticket>.md`) unless directed otherwise.

## Implementation discipline — red, green, refactor
For every implementation task, follow red → green → refactor:

1. **Red:** confirm there is a failing test that pins the desired behavior. If coverage already exists, run it first and verify it fails in the expected way (or covers the change you are about to make). If coverage is missing, write the failing test *before* any production change.
2. **Green:** make the minimum code change to pass.
3. **Refactor:** clean up with the test still green.

The test is the spec, not the code. This applies even to "pure refactor" work — if existing tests pass unchanged, that *is* the green step. If they fail after a refactor, fix the code, not the test. Plans and task lists for non-trivial work should call this approach out explicitly so it isn't quietly skipped.
