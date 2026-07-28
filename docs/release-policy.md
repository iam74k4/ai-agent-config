# Release policy

## Current policy

- Work happens on topic branches created from `main`.
- Topic-branch pushes are not releases and must not receive SemVer tags.
- After a release change is merged into `main`, create one annotated `vMAJOR.MINOR.PATCH` tag on the released `main` commit.
- Choose the version according to SemVer: breaking changes are major, compatible capabilities are minor, and fixes or maintenance are patch releases.

## Historical tags

The repository contains tags created by an older policy that required a tag for every push. Some of those tags are not reachable from `main`, so they must not be treated as release records:

```text
v0.1.0
v0.1.1
v0.1.2
v0.1.3
v1.0.2
v1.1.0
v1.3.0
```

They remain in place to avoid rewriting public history. Future releases follow the current policy only.
