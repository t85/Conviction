# Conviction

Every agent working in this repository reads this file first.

## What this project is

Conviction is a new project. It has no application code yet, so its purpose,
users and stack are still to be decided. Whoever makes those decisions records
them here, and the factory's intake judges every issue against this section.

## Fresh checkout

No setup is needed yet. When the first stack lands, list here the commands that
install dependencies and any env files to copy (for example
`cp .env.example .env`).

## Dev server

None yet. When one exists, document how to start it on a given port, e.g.
`PORT=<port> npm run dev`, so the factory's builder and reviewers can open pages.

## Validation

`bash factory/checks.sh` is the single source of truth. Until the stack settles
it detects what the repo contains (`package.json`, `pyproject.toml` or
`requirements.txt`, `go.mod`, `Cargo.toml`) and runs that stack's lint,
typecheck, test and build commands, plus `git diff --check` against the base
branch. When the stack settles, replace the detection with the exact commands
and list them here.

## Software factory

`/factory run` builds every open GitHub issue labeled `factory` through
intake → spec → build → gate → review → approve, one PR per issue. State is in
`factory/jobs/` (gitignored); `factory/bin/job` is its only writer. Checks:
`factory/checks.sh`. Dashboard: `cd factory && python3 -m http.server`, then
open http://localhost:8000/dashboard.html.
