# Repository Instructions

<!-- generated:rules:start -->
<!-- Generated from rules; do not edit directly. Edit rules/ and run: node scripts/sync-rules.mjs -->

## General requirements

- Keep edits focused and preserve existing behavior unless the request requires a change.
- Read applicable path-scoped instructions before modifying files.
- Never commit credentials, local configuration, generated workspace files, or absolute machine paths.
- Run the relevant verification before completing a change.
- Keep instructions concise and move guaranteed checks to scripts or CI.

## Git workflow

- Create topic branches from `main`; do not commit directly to `main`.
- Use Conventional Commits: `type(scope): subject`, with an English, lowercase imperative subject.
- Commit one logical change at a time and do not include generated summaries.
- Do not create release tags for ordinary topic-branch pushes.
- Create an annotated SemVer tag only for a released commit that is already reachable from `main`.

<!-- generated:rules:end -->

## Documentation

- Prefer concise Markdown with explicit language tags on code blocks.
- Update user-facing setup documentation when setup behavior changes.
