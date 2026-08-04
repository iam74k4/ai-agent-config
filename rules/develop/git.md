---
id: git
description: Git workflow, commits, and release tags
alwaysApply: true
---

# Git workflow

- Create topic branches from `main`; do not commit directly to `main`.
- Use Conventional Commits: `type(scope): subject`, with an English, lowercase imperative subject.
- Commit one logical change at a time and do not include generated summaries.
- Do not create release tags for ordinary topic-branch pushes.
- Create an annotated SemVer tag only for a released commit that is already reachable from `main`.
