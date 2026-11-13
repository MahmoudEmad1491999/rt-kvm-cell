# 0002 — Buildroot pinned as a git submodule

**Context.** The project needs a fixed, reproducible Buildroot version.
CLAUDE.md allows either a git submodule or a download with sha256.

**Decision.** Git submodule pointing to `https://github.com/buildroot/buildroot.git`
at the `2026.02.x` LTS tag `2026.02.3` (commit `679b9ead`).

The latest Buildroot LTS as of 2026-11-14 is the `2026.02.x` series, which
follows the annual `.02` long-term-support cadence.  Tag `2026.02.3` is the
latest point release on that branch at time of writing.

**Alternatives considered:**
- Download + sha256 — more explicit but requires a manual fetch step and a
  separate tool to verify; a submodule gives `git submodule update --init`.
- `2024.02.x` — an older LTS; using the newest available LTS keeps us closer
  to upstream fixes and matches Linux 6.18 LTS.

**Known limitation.** A project-level security hook prevents writing to
`.gitmodules` from within an automated agent session, so the optional
`branch = 2026.02.x` and `shallow = true` convenience fields could not be
set.  Anyone who wishes to add them can run:

```
git config -f .gitmodules submodule.buildroot.branch 2026.02.x
git config -f .gitmodules submodule.buildroot.shallow true
```

The pinned commit in the git index is authoritative regardless of the
`branch` field.

**Consequences.** `make submodule-init` runs `git submodule update --init
--depth=1` to populate `buildroot/`.  `ci/check.sh` validates that
`.gitmodules` and the `br2-external/` skeleton are present without requiring
the submodule to be initialised.
