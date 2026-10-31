#!/usr/bin/env bash
# The repo's checks. Exit 0 only when the branch is fit to review.
#
# The gate runs this script from the main checkout with the job's worktree as
# the working directory. Keep it fast, deterministic and non-interactive: no
# watch modes, no prompts, nothing that rewrites files.
#
# Conviction has no application code yet, so this script detects the stack the
# first jobs introduce and runs its standard checks. Once the stack settles,
# replace the detection with the project's exact commands.
set -euo pipefail

# Whitespace errors and leftover conflict markers in the branch's changes.
cfg="$(dirname "${BASH_SOURCE[0]}")/config.json"
base="origin/$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["base_branch"])' "$cfg")"
if git rev-parse --verify --quiet "$base" >/dev/null; then
  git diff --check "$base...HEAD"
fi

ran=0

if [[ -f package.json ]]; then
  ran=1
  if [[ -f pnpm-lock.yaml ]]; then pm=pnpm; pnpm install --frozen-lockfile
  elif [[ -f yarn.lock ]]; then pm=yarn; yarn install --frozen-lockfile
  elif [[ -f package-lock.json ]]; then pm=npm; npm ci --prefer-offline --no-audit --no-fund
  else pm=npm; npm install --no-audit --no-fund
  fi
  has_script() { node -e "process.exit(require('./package.json').scripts?.['$1'] ? 0 : 1)"; }
  for s in lint typecheck test build; do
    if has_script "$s"; then
      echo "== $pm run $s"
      CI=1 "$pm" run "$s"
    fi
  done
fi

if [[ -f pyproject.toml || -f requirements.txt ]]; then
  ran=1
  python3 -m venv .venv-factory >/dev/null
  # shellcheck disable=SC1091
  source .venv-factory/bin/activate
  pip install -q --upgrade pip
  if [[ -f requirements.txt ]]; then pip install -q -r requirements.txt; fi
  if [[ -f pyproject.toml ]]; then pip install -q -e ".[dev]" 2>/dev/null || pip install -q -e .; fi
  if command -v ruff >/dev/null; then echo "== ruff check"; ruff check .; fi
  if command -v mypy >/dev/null && grep -q '\[tool.mypy\]' pyproject.toml 2>/dev/null; then echo "== mypy"; mypy .; fi
  if command -v pytest >/dev/null; then
    echo "== pytest"
    rc=0; pytest -q || rc=$?
    [[ $rc -eq 0 || $rc -eq 5 ]] || exit "$rc"  # 5 = no tests collected
  fi
  deactivate
fi

if [[ -f go.mod ]]; then
  ran=1
  echo "== go vet / go test"; go vet ./...; go test ./...
fi

if [[ -f Cargo.toml ]]; then
  ran=1
  echo "== cargo clippy / cargo test"; cargo clippy --all-targets -- -D warnings; cargo test
fi

if [[ $ran -eq 0 ]]; then
  echo "No application stack found yet (no package.json, pyproject.toml, go.mod or Cargo.toml). Only the diff check ran."
fi
