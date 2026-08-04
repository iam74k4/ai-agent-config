---
name: conventional-commit
description: Write a Conventional Commit message for staged changes. Use when composing or fixing a commit message, or when the user asks for a commit following this repository's git workflow rules.
---

# Conventional commit

Category: develop.

Help compose a commit message that follows this repository's git workflow
(`rules/develop/git.md`).

## Steps

1. Inspect what is staged.

   ```bash
   git status --short
   git diff --cached
   ```

2. Group the change into a single logical unit. If the diff mixes unrelated
   changes, suggest splitting it into separate commits.
3. Pick the `type` from the change: `feat`, `fix`, `docs`, `refactor`, `test`,
   `chore`, `ci`, `build`, or `perf`.
4. Derive a `scope` from the touched area (for example `setup`, `rules`,
   `scripts`, `docs`). Omit the scope only when no single area fits.
5. Write the subject as an English, lowercase, imperative phrase with no
   trailing period.

## Format

```text
type(scope): subject

optional body explaining what and why, wrapped at ~72 columns
```

## Rules

- One logical change per commit.
- Do not include generated summaries or tool attribution in the message body.
- Do not create release tags for ordinary topic-branch commits.
