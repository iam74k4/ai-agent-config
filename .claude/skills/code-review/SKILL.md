---
name: code-review
description: Run a structured self-review of pending changes before committing. Use before opening a pull request or when the user asks to review, sanity-check, or double-check a diff.
---

# Code review

Category: develop.

Review the pending diff against a consistent checklist before it is committed
or pushed.

## Steps

1. Read the full diff.

   ```bash
   git diff
   git diff --cached
   ```

2. Walk the checklist below and note concrete findings with `file:line`
   references.
3. Report findings grouped by severity (blocking, then non-blocking). If the
   diff is clean, say so plainly.

## Checklist

- **Scope**: the change stays focused and does not modify unrelated code.
- **Behavior**: existing behavior is preserved unless the change requires
  otherwise.
- **Secrets**: no credentials, tokens, local config, or absolute machine paths
  are committed.
- **Errors**: failure paths and edge cases are handled, not just the happy
  path.
- **Tests**: behavior changes come with matching tests or a stated reason none
  are needed.
- **Docs**: user-facing documentation is updated when behavior changes.
- **Verification**: the relevant build, lint, or test command has been run.
