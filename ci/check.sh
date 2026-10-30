#!/usr/bin/env bash
# Local verification (agent + you). Grows with the project; see CLAUDE.md.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== shellcheck =="
shopt -s nullglob globstar
sh_files=(scripts/**/*.sh ci/*.sh br2-external/**/*.sh)
[ ${#sh_files[@]} -gt 0 ] && shellcheck "${sh_files[@]}"

if [ -f Makefile ]; then
  echo "== make check =="
  make check
else
  echo "no Makefile yet — skipping build/tests"
fi
echo "ALL CHECKS PASSED"
