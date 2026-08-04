---
name: readme-scaffold
description: Scaffold or refresh a README that follows the repository's README rule. Use when creating a new README, restructuring an existing one, or when the user asks for project documentation.
---

# README scaffold

Category: docs.

Produce or refresh a `README.md` that satisfies `rules/docs/readme.md`.

## Steps

1. Gather the project name, a one-line purpose, prerequisites, setup commands,
   and the license.
2. Fill in the template below, keeping the overview short.
3. Replace every fenced code block language placeholder with the real language,
   and use a Mermaid block only when a small diagram explains the structure
   better than prose.
4. Verify that every link resolves.

## Template

````markdown
# Project name

Short overview of what the project does and who it is for.

## Prerequisites

- Requirement one
- Requirement two

## Setup

1. First step.

   ```bash
   command --here
   ```

2. Second step.

## License

[MIT](LICENSE)
````

## Rules

- Exactly one `#` title.
- Numbered setup steps, with prerequisites stated when relevant.
- A language identifier on every fenced code block.
- State or link the project license.
