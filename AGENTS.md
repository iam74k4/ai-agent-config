# Repository Instructions

## Always

- Keep changes focused on the user’s request and preserve existing behavior unless a change is required.
- Read applicable path-scoped instructions before modifying files.
- Do not commit secrets, generated local configuration, or machine-specific paths.
- Run the relevant validation before handing off a change.
- Use Conventional Commits: `type(scope): subject`, with an English, lowercase imperative subject.

## Git and releases

- Create topic branches from `main`; do not commit directly to `main`.
- Tag only released commits that are already on `main`. Do not tag ordinary topic-branch pushes.

## Documentation

- Prefer concise Markdown with explicit language tags on code blocks.
- Update user-facing setup documentation when setup behavior changes.
