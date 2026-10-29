# CLAUDE.md (awkit-docs)

This repo holds the system-level documents for `awkit`: `architecture.md`, `design-guide.md`, `interface-registry.md` and `roadmap.md`. It contains no code.

## Rules for editing

- **Open source, nothing confidential.** This repo is public. Never add company or employer names, hostnames, ticket project keys, custom-field IDs, repo or org names, people's names, private skill or plugin names, or anything copied from private reference material. Organization specifics live only in users' local config.
- **Placement.** Cross-tool contracts, ownership of responsibilities and safety invariants belong in `architecture.md`. Conventions every tool follows belong in `design-guide.md`. Details internal to one tool belong in that tool's own `docs/design.md` (or `docs/interface.md`); the architecture records them only as constraints and open topics in section 20.
- **Keep documents consistent.** An architecture change must update, as needed:
  - `interface-registry.md` (tools, layers, consumers derived from the "Uses" lines in section 5);
  - `roadmap.md` (slices and order from section 18.2, done criteria and non-goals from section 19, the spike list from section 8.6);
  - `design-guide.md` if a convention changes, and the version/status line of every document touched.
- **Interface changes.** A tool session that changes its interface updates its row in `interface-registry.md` (version, status) after checking its listed consumers.
- **Hook feature candidates.** Add candidates to the list in `roadmap.md` as tool designs proceed.
- Never run destructive git commands (reset, checkout of files, clean, restore, force-push).

## Repository workflow

- Work in a git worktree on a branch named `<type>/<short-slug>`, never in the main checkout (design guide section 17).
- PR titles are Conventional Commit headers; they become the squash commit, the version bump and the changelog line (architecture section 18.3). Do not use `!` before 1.0 (a breaking change before then is a `feat` whose title names the break).
- `make verify` (markdown lint) must pass before every commit.
- Never use `--no-verify`. Check PR titles, bodies and comments with `guard text` where the private-content guard is installed (architecture section 18.7).
- Never merge a PR without the maintainer's explicit instruction for that PR; merges go through `awkit-ci`'s `scripts/pr-merge` (architecture section 18.6).
- Never hand-edit `CHANGELOG.md` or the version in `pyproject.toml`; the release job owns them.
