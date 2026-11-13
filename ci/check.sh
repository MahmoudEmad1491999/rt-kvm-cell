#!/usr/bin/env bash
# Local verification (agent + you). Grows with the project; see CLAUDE.md.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== shellcheck =="
shopt -s nullglob globstar
sh_files=(scripts/**/*.sh ci/*.sh br2-external/**/*.sh)
[ ${#sh_files[@]} -gt 0 ] && shellcheck "${sh_files[@]}"

echo "== buildroot submodule =="
if [ ! -f .gitmodules ]; then
  echo "ERROR: .gitmodules missing — run: git submodule add ... buildroot" >&2; exit 1
fi
grep -q 'path = buildroot' .gitmodules || { echo "ERROR: .gitmodules has no buildroot entry" >&2; exit 1; }
grep -q 'url.*buildroot' .gitmodules    || { echo "ERROR: buildroot submodule has no url" >&2; exit 1; }
echo "  .gitmodules ok"

echo "== br2-external skeleton =="
for f in br2-external/external.desc br2-external/Config.in br2-external/external.mk \
         br2-external/package/Config.in; do
  [ -f "$f" ] || { echo "ERROR: $f missing" >&2; exit 1; }
done
grep -q '^name:' br2-external/external.desc || { echo "ERROR: external.desc missing 'name:'" >&2; exit 1; }
grep -q '^desc:' br2-external/external.desc || { echo "ERROR: external.desc missing 'desc:'" >&2; exit 1; }
echo "  br2-external skeleton ok"

if [ -f Makefile ]; then
  echo "== make check =="
  make check
else
  echo "no Makefile yet — skipping build/tests"
fi
echo "ALL CHECKS PASSED"
