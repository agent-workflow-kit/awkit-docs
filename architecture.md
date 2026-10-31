# awkit: Architecture

Status: approved architecture (v1.11), 2026-10-31. Produced from the architecture brainstorming session. v1.5: review-respond lists gatectl as an optional dependency (auto-push / auto-reply decisions). v1.6: renamed cw → awkit; tools unprefixed. v1.7: CI, versioning, release and repository workflow (sections 17, 18.3, 18.6–18.8); review-watch wording, states and defaults rewritten generically. v1.8: claude-session design session: spike results; session model revised (section 8: kind profile fields, prompt delivery via the system prompt, report outbox, frozen artifacts, hook semantics, `pre-launch`, `wait`); sandbox required for third-party-reading kinds and session isolation (section 13.1); memoctl `context` contract (section 16). v1.8 (review pass 1): claude-session's session directory split into an agent-visible and a private part; `not-started` state, sticky escalation, `stop`, `start --resume`; resume carry-over rules; per-call `--sandbox`/`--setting-sources`/`--reads-third-party`; isolation keyed on `reads_third_party` or the sandbox; git-dir and Claude-config write denies; agent-spawn's repo-config baseline extended (sections 8, 9.1, 13, 16). v1.8 (review pass 2): pending runs and one adoption rule; a fixed launch order; `stop` semantics; state display priority; skill-first bootstrap and the SessionStart directory line; report permissions and `--add-dir` for every run; `implicit_done`, `--input-file`, `--reset`; respond git hardening and nested Claude-config denies; agent-spawn's baseline extended to worktree metadata (sections 8, 9.2, 13, 16). v1.8 (review pass 3): section 8 trimmed to the cross-tool contract, linking to claude-session's `docs/interface.md` as the single normative source; resume without a captured Claude id starts a fresh conversation; git internals denies and `GIT_CONFIG_COUNT` hardening for every third-party-reading run; unsafe-path rules; `sandbox_lowered` baseline; agent-spawn's baseline extended to included config, `core.hooksPath` and submodule hooks (sections 5.1, 8, 9, 13, 20, 21). v1.8 (review pass 4 + live verification): respond agents no longer commit (the git dir is read-only for third-party-reading runs; review-respond commits and pushes on confirm); headless sessions read `stream-json`; AskUserQuestion shows as `needs-input(question)`; one definition of session-writable paths and unsafe write targets; promotion through `start --resume` (sections 5.3, 8, 9.3, 9.4, 10.3, 12.1, 13, 14, 19, 21). v1.8 (safety check + live E): each respond round runs in a disposable checkout (the fork takes `--cwd`; confirm applies the listed files in a clean checkout); deny-root sandbox reads with an allowlist; the cwd's `.git` always write-denied; context carry into third-party runs listed as a residual risk (sections 5.3, 8.5, 9.4, 10.3, 12.1, 13, 19). v1.9: termctl design session: termctl owns placement (named placements and label-matched rules in its config), its ids name panes and are paired with a socket path, the status prefix became named markers (`termctl mark`/`unmark`), and `close` refuses running panes (`reason: running`) and kills only the managed pane (sections 5.1, 9.3, 9.6, 20, 21). v1.10: wtctl design session: live verification showed the hardened git flag set left execution and redirection paths open, so section 13.2 rule 10 now holds the full, verified hardened git invocation; wtctl owns the repo-config baseline (`create` records it, `remove` and `baseline check` compare it, a human re-records it with `baseline accept`); wtctl `extract` owns the safe-extraction rules review-respond's confirm uses; `adopt`/`forget`, `status`, `in_use`; per-worktree port/container prefixes dropped (sections 5.1, 5.3, 9.2, 9.4, 9.5, 10.3, 13.2, 20, 21). v1.10 (wtctl review pass 1): the hardened git invocation adds the verified blocks for forged ancestry (replace refs, grafts, commit-graph), ssh batch mode, network timeouts, no HTTP redirects and blanked repository extra headers, and wtctl verifies ancestry by content before trusting "is it pushed?"; the baseline parses config (minus routine tracking keys), covers only the worktree's own admin entry plus excludes, is recorded after bootstrap and splits into `git` and `claude` classes (`remove` refuses on `git` only); wtctl's default locations lie outside hidden and XDG directories; review-respond's clean checkout for confirm is a second, fresh throwaway; agent-spawn adopts and forgets with a holder; wtctl may obtain tokens from a configured token command (sections 5.1, 5.3, 9.2, 9.4, 9.5, 10.3, 13.1, 13.2, 13.3, 20, 21). v1.10 (wtctl review pass 2): holders on any worktree record, and `remove` refuses a held record (`held`), so agent-spawn passes `--holder` to `create` and `remove`; removing an adopted worktree without a human exits 13; remote tips come from a remote listing, never from refs (replaced by the mirror in the safety check), and the shallow push from a throwaway is verified; review-respond's clean checkout is fetched from the remote and pushed to the clone's recorded URL; wtctl's baseline ignores the sandbox's host traces (sections 5.1, 9.5, 13.2, 20). v1.10 (wtctl review pass 3): review-respond's clean checkout is fetched over, and pushed to, the clone fetch URL; the baseline covers the submodule git dirs under a worktree's own admin entry; worktrees with initialized submodules need a human to remove in v1 (sections 5.1, 5.3, 9.5, 13.2, 20). v1.10 (wtctl safety check): tool-owned mirror for network git (reachability decisions use a repository only the tool configures, and no network fetch targets an agent-writable clone), fd-based deletion (never `git worktree remove`), never `git worktree repair`, non-network git with protocols `none` and lazy fetching off, local repositories addressed by plain path (sections 5.1, 13.2, 20). v1.10 (wtctl safety re-check): pack-based transfer (objects move into or out of an agent-writable repository only as tool-built packs, every command against one runs with protocols `none`, and no `fetch`, `clone` or `push` runs against it), deletions and tree walks never cross mount points and are anchored to location identities recorded when the location was first recorded, `--no-ext-diff` required on diff-family commands (section 13.2). v1.10 (wtctl anchor re-check): recorded location identities change only through a human, never automatically; tool walks open entries non-blocking, never read FIFOs, sockets or devices, and run under a killable deadline with byte and entry bounds per computation; the file-system defenses are scoped to planted configuration and mount tricks, not to deliberate sabotage by a trusted, unsandboxed agent (section 13.2). v1.11: jobsctl design session: a tool may signal the process group it created for a job it runs (not only for a hook); jobsctl jobs get jobsctl's allowlisted base environment (plus an optional env file) instead of the runner's whole environment, and a missing `--pass-env` fails the job; implicit queues, `effective_free`, early start triggers, `pre-start` hooks run in the job's shim while it holds its slot, `retry` keeps the job id, `resolve --as`, `post-cancel`, `wait`; the cron fallback needs no separate `jobsctl reconcile` entry (sections 3.4, 5.1, 7.7, 20, 21). v1.11 (jobsctl review pass 1): `--pass-env` values come from the user's env file that every jobsctl pass loads, not from the submitter, and jobsctl has no config environment variables; a job waiting for an automatic retry stays queued; a SIGTERM that was not a `cancel --force` ends a job failed (`terminated`); hooks opt into receiving output tails; the global free count includes only jobs that could start under their queue caps (sections 5.1, 20). v1.11 (jobsctl review pass 2): a job held because its command exited 13 may also be retried under its id; inherited (allowlisted) environment values come from the process that started the trigger chain, and only the env file and fixed config values are trigger-independent; the env file is a trust anchor; output masking is best-effort; awkit's bundled jobsctl adapter reproduces `jobsctl cron install`'s line (sections 5.1, 7.7, 13.3, 20, glossary). v1.11 (jobsctl review pass 3): early start triggers only where a job can become startable (`add`, a job's end, `cancel` of a starting job, `release`, `retry`); after a shim loss the helper signals the job's process group, and reconcile ends a job canceled (`forced`) when a force request was committed; hook output is no longer stored; after the jobsctl spot checks, a `PATH` set in jobsctl's config also applies to hooks and jobsctl's own processes, and env-file values reach only hooks and jobs (sections 5.1, 20).

IDs in parentheses (e.g. QR-7) point to the author's private decision log, which is not published; this document is self-contained and authoritative. ID prefixes used here: QG goals, QE environment, QR architecture reset, QRT agent runtime, QSC security, QD development.

This document is destined for the `awkit-docs` repo. The companion document `design-guide.md` holds the conventions every tool follows. This document holds cross-tool contracts, ownership of responsibilities and safety invariants; details internal to one tool are recorded as constraints on that tool's design session (section 20).

---

## 1. Purpose

`awkit` ("agent workflow kit") is a modular, open-source system for running Claude Code agents as part of a developer's daily work:

- Watch for PRs where you are asked to review, run a reviewer agent, and let you post the result with one key.
- Pull tickets from one or more boards, rank them, and start an agent on the next one in its own git worktree and tmux window.
- Let working agents brainstorm with you, ask for your judgment, and report when they are done.
- When review comments land on a PR an agent opened, resume a fork of that same agent session to respond.
- Keep you informed (Slack, Home Assistant, desktop, tmux) when something needs you.
- Give you a TUI to see and steer all of it, while every piece stays usable on its own.

It is built for one user first (the author), but individual tools, especially the reviewer, are meant to be shared with teammates or anyone else.

## 2. Hard constraints

| # | Constraint | Consequence |
|---|---|---|
| C1 | **Open source, nothing confidential.** Repos are public in the `agent-workflow-kit` GitHub organization. | No employer names, ticket project keys, custom-field IDs, hostnames, repo or org names, or code/skills copied from private reference material. Organization specifics live only in the user's local config and adapter overlays. |
| C2 | **Every tool works fully standalone.** | No tool needs the harness, a bus, a shared library, or a shared contracts package. |
| C3 | **Any third-party CLI must be pluggable** without complying with anything of ours. | The harness and coordinating tools adapt to tools, never the reverse. |
| C4 | **Platforms:** Linux and WSL (Ubuntu) for everything; macOS for tools likely to be shared. | macOS is required for forgectl, pr-comment, pr-watch, review-run, review-watch, agent-spawn, claude-session, wtctl, jobsctl and gatectl (termctl only if interactive use is wanted). No Linux-only assumptions in these tools; WSL quirks documented (e.g. file watching under `/mnt/c` is unreliable). |
| C5 | **Terminal:** tmux only for now. | The terminal boundary (`termctl`) stays clean so another backend (e.g. iTerm) can be added later. |
| C6 | **Developed in parallel** by many independent Claude sessions, possibly several per tool. | One repo per tool, interface-first development, per-tool schemas and semver. |
| C7 | **Safe public defaults.** | Shipped defaults are conservative; the author's machine config is more permissive. |

## 3. Core principles

### 3.1 Tools never adapt to the harness; the harness adapts to tools

Each tool we build is an ordinary standalone CLI, as unaware of the harness as `gh` or `jq`. It has its own name, config, state directory, output format and version. It does not emit to a bus, does not assume a global namespace, and does not import a shared contract library. If someday a third-party CLI does the same job better, it plugs in through an adapter without changing.

### 3.2 Layered composition

Tools may use other tools of ours, exactly as they use `gh`. That is composition, not dependence on the harness. The rules:

- A tool may depend on tools in a lower layer or in the same layer, and on third-party CLIs, provided the dependency graph stays acyclic.
- The hard rules are **no upward awareness** (a tool is never aware of the tools that call it) and **no cycles**. Layers are a guide to direction, not an additional constraint.
- The harness (`awkit`) is just the top-layer tool. It knows about the others only through configuration and adapters.
- Coordinating tools (e.g. `notice-route`) bind to arbitrary lower tools the same way, including tools we do not own.
- Shareable tools must not require user-only pieces (tmux, personal notifiers). For example, agent-spawn uses termctl only for interactive window placement and wtctl only when a worktree or a local clone is needed; a headless launch with `--worktree none` needs neither.

Rule of thumb: **a tool is something a human would find useful on its own at a terminal.** Anything that only makes sense as glue between tools belongs to a higher tool or to the harness.

### 3.3 Edge bindings

Each dependency edge between tools is bound in one of three ways, chosen per edge in the depending tool's own design session (QR-8):

| Type | Name | When | Mechanism |
|---|---|---|---|
| A | Hard binding | Tightly coupled pair | Call the lower tool by name and parse its documented output. |
| B | Configurable command | Alternatives share identical or similar inputs and outputs (like `cat`/`bat`/`glow`) | A config entry names the command, defaulting to our tool. |
| C | Adapter | Alternatives have different inputs and outputs | A per-alternative adapter maps the lower tool into the higher tool's model. |

### 3.4 Other cross-cutting principles

- **Hooks everywhere.** Every tool exposes `pre-`/`post-` lifecycle hooks at its meaningful steps. A pre-hook can veto the step or escalate it (holding it for a human). Tools that detect external changes (e.g. pr-watch) also expose `on-<event>` hooks, which cannot veto. This is how users (and the harness) attach behavior such as notifications or policy checks anywhere (QR-2, QR-17).
- **Opaque labels.** Tools that create long-lived objects (agents, jobs, worktrees) accept `--label key=value`, store it, and filter on it. No tool assigns built-in meaning to a label key; cross-tool links are expressed this way (QR-11; design guide section 9).
- **Canonical identifiers.** A repo is always identified as `host/<full project path>` (flags, labels, config keys). A PR is referenced by its URL or as `host/<full project path>#N` (GitLab MR numbers written without `!`); every tool accepts both forms and `--json` output always uses the `#N` form.
- **Explicit arguments, never caller identity.** A tool never behaves differently depending on who calls it. Behavior may differ by explicit arguments such as `--kind`.
- **Escalation is always allowed.** Any autonomous step can be paused by Claude or by a gate to ask for the user's judgment (QG-5).
- **Safe public defaults, permissive personal config** (C7, QG-5, QSC-2).
- **Minimal dependencies.** Each dependency must justify itself (QE-15).
- **Untrusted text travels in files.** Untrusted or agent-generated text is passed between processes only in files or on stdin, never in argv or env (section 13.2 rule 2).
- **Never destroy work.** No tool reverts, resets or cleans files with git. Teardown always refuses live sessions, and refuses dirty or unpushed worktrees unless a human passes `--force`; automation never passes `--force`. Processes are only ever signaled by an exact PID the tool started (verified by PID plus process start time), or through a process group the tool itself created for a hook or for a job it runs (section 8.2, section 5.1 jobsctl; design guide section 8). Tool-performed git operations never run repository-controlled hooks or other repository-controlled executable config, and never force-push (section 13.2 rule 10).

### 3.5 Naming

Tool names carry no shared prefix: a tool does not belong to the harness (section 3.1). Names follow four rules (design guide section 1):

1. Primitives that manage a resource: `<resource>ctl` (forgectl, ticketctl, wtctl, termctl, gatectl, jobsctl, memoctl).
2. Tools bound to a vendor or channel: `<vendor-or-channel>-<role>` (claude-session; slack-notice, ha-notice, desktop-notice). A future vendor session tool would be e.g. `codex-session`.
3. Workflow/composite tools: `<family>-<verb>`, always hyphenated (pr-watch, pr-comment, review-run, review-watch, review-respond, ticket-queue, ticket-create, ticket-work, notice-route, agent-spawn, session-audit, self-improve).
4. The harness is `awkit` ("agent workflow kit"); the docs repo is `awkit-docs`. New names must be checked free on PyPI, Homebrew, apt and common PATHs.

A tool's repo, distribution, executable, config and state dirs, bundled plugin and env-var prefix all derive from its name (section 6). A tool may declare a different env prefix when the derived one would collide with another namespace; claude-session uses `CSESSION_` to stay out of Claude Code's `CLAUDE_*` namespace.

**Agent session role.** claude-session is explicitly Claude-specific. It is one implementation of an **agent session role**: run and supervise one coding-agent session, report its outcome, resume and fork it. Higher tools (agent-spawn, gatectl, ticket-queue and the skill-wrapper tools) treat it through that role, and their edge to it is where a second vendor's session tool would plug in later (binding C, section 3.3). No second vendor is built now.

## 4. System overview

```text
L4  awkit              harness: tool registry, adapters, label-derived state graph, rules,
                       tick/run loop, wire/unwire, dashboard TUI, merged audit timeline

L3  review-watch    review-run    review-respond    ticket-work
    session-audit*  self-improve*

L2  pr-watch    pr-comment    ticket-queue    ticket-create
    notice-route    agent-spawn

L1  forgectl    ticketctl    wtctl    termctl    claude-session
    jobsctl    gatectl    memoctl
    slack-notice    ha-notice    desktop-notice

L0  third party: git, gh, glab, tmux, claude, jq, curl,
    Jira REST API, Slack incoming webhooks, Home Assistant REST API

* post-v1 (may be built in parallel if there is capacity)
```

Repos: one per tool (named exactly as the tool), plus `awkit` (the harness) and `awkit-docs` (this document, the design guide, the roadmap and the interface registry). During development, all repos are checked out as sibling directories of one local working folder; they are published as public repos in the `agent-workflow-kit` GitHub organization. Tool names follow the naming rules in section 3.5; there is no shared tool prefix.

## 5. Tool catalog

Each entry gives the tool's job, its main commands (indicative; each tool's own design session finalizes its interface), what it uses, and notes on the contracts other tools rely on. "Uses" lists dependency edges; their binding type (A/B/C) is decided in that tool's session unless stated. Tool-internal constraints are in section 20. Commands that take untrusted or agent-generated text take it as `--<name>-file <path>` or `-` for stdin (design guide section 4.1).

### 5.1 Layer 1: primitives

#### forgectl

Normalized access to pull/merge requests across GitHub and GitLab.

- Commands: `prs` (filters incl. "review requested from me by name"), `show`, `diff`, `comments`, `reviews`, `ci`, `merge <pr> [--auto]`, `browse`.
- Uses: `gh`, `glab` (backends).
- Notes: `merge` is confirm-by-default (section 12.4); `--auto` uses host-native auto-merge / merge-when-pipeline-succeeds. `merge --yes` without a TTY requires `--expected-head <sha>` (exit 2 without it); if the PR head differs, it refuses (exit 20, `reason: stale_head`). With `--auto`, the expected head is enforced through the host's head-match option (e.g. a match-head-commit or sha parameter); where the host has none, `--auto` with `--expected-head` refuses (exit 20, `reason: no_head_match`). *When* to merge is decided elsewhere (QR-12). Git-host credentials: `token_env` is configured per host (`hosts.<host>.token_env`); forgectl sets `GH_TOKEN`/`GITLAB_TOKEN` for each `gh`/`glab` call from it, avoiding stale CLI logins under cron (QE-9). Ships an optional `browse` TUI.

#### ticketctl

Normalized ticket access. Jira first; other providers later.

- Commands: `get`, `search`, `transition`, `comment --body-file`, `create --body-file`, `update`, `sprint` helpers.
- Uses: Jira REST API.
- Notes: Writes support `--dry-run` and are confirm-by-default. ticketctl has no pending-confirmation store: a non-interactive write without `--yes` exits 13 without acting, and the calling tool records the pending confirmation (section 12.4). Field mappings (story points, acceptance criteria, sprint field and so on) are config, never code (C1).

#### wtctl

Git worktrees, throwaway checkouts, and the mapping from repo ids to local clones.

- Commands: `create --repo <id> [--branch <name> | --detach] [--base <ref>] [--ref <sha>] [--copy-env] [--holder <h>]`, `create --throwaway --repo <id> --ref <sha>`, `list`, `show`, `status [--merged-head <sha>] [--holder <h>]`, `remove [--merged-head <sha>] [--holder <h>] [--force] [--dry-run]`, `bootstrap [--copy-env]`, `extract`, `baseline check|accept`, `adopt <path> [--holder <h>]`, `forget [--holder <h>]`, `locate <repo-id>`, `clone`, `label add/remove`, `reconcile`, `prune --throwaways`, `export`.
- Uses: `git` (2.34 or newer).
- Notes: wtctl's `docs/interface.md` is the single normative source for its rules.
  - Owns the repo id → local clone mapping (`repos.<id>.clone: <dir>`, then optional discovery under configured search roots, then optional auto-clone). agent-spawn, review-run and ticket-work resolve local clones through `wtctl locate`.
  - Worktrees are created in a central, configurable location (wtctl's `docs/interface.md`, section Locations); wtctl's default throwaway and worktree locations lie outside hidden home directories and the XDG homes, so claude-session can run isolated sessions in them. An explicit `--branch` is used verbatim (callers such as ticket-work build ticket-based names), else a configurable template; a branch checked out elsewhere is refused (`reason: branch_in_use`). Dependency bootstrap (the project's own commands, per repo) runs on `create`; env-file copying is opt-in per call and per repo. Port and container isolation is out of scope. Supports labels; records are addressed by id (`wt-` + 8 base32 characters) or absolute path.
  - **Every git command wtctl runs uses the hardened git invocation** (section 13.2 rule 10).
  - **Repo-config baseline.** wtctl records the baseline of section 13.2 rule 10 when it creates a worktree (after bootstrap) or `adopt`s one it did not create, compares it before removal (git-class items only) and on `baseline check` (either class; exit 20, `reason: repo_config_changed`), and re-records it only through `baseline accept`, a human action after inspecting the change.
  - `remove` is confirm-by-default (section 12.4). It refuses (exit 20) among others a worktree whose git pointers do not match its record (`unlinked`), a locked worktree (`locked`), a changed git-class baseline item (`repo_config_changed`; changed Claude project config is reported as a warning), a worktree a process still uses (`in_use`; nothing overrides it), a record another holder still relies on (`held`), and dirty or unpushed worktrees (`dirty`, `unpushed`); a human `--force` overrides only `held`, `dirty`, `unpushed` and a failed pre-removal fetch, and `--yes` never bypasses a refusal. In v1 a worktree with initialized submodules is refused `dirty` (`nested_repos`) and needs a human `--force` (wtctl's `docs/interface.md`, section Content checks). The full precedence order is in wtctl's `docs/interface.md`, section Remove order. "Unpushed" means HEAD is not reachable from the remote's branches, freshly fetched from the URL recorded at create into **wtctl's own mirror** (a treeless bare repository under wtctl's state dir that only wtctl configures; the user's clone is never the target of a network fetch, and a base commit the clone lacks reaches it from the mirror), **and** is not equal to a supplied `--merged-head <sha>`; callers pass the merged PR head so squash merges do not block removal. Reachability is verified by content, not only by git's ancestry walk (section 13.2 rule 10; wtctl's `docs/interface.md`, section Reachability). It deletes the worktree itself, fd-based from its recorded root (never through `git worktree remove`), and deletes the branch only if wtctl created it and nothing would be lost. `status` runs the same checks without removing (it takes `--merged-head` and `--holder`), and `remove --dry-run` is the same as `status`.
  - **Throwaway checkouts.** `create --throwaway --ref <sha>` creates a separate disposable clone (not a linked worktree, so nothing run in it can touch the user clone's `.git` hooks or config): `git init` plus a fetch of only that sha, from the local clone when it has the commit, else from the remote, with no remote, hooks, filters or credentials persisted. `remove` of a throwaway skips the confirmation and the dirty/unpushed checks, runs no git and deletes without following links. wtctl itself never runs git in a throwaway after creating it; a caller may run git there only with the hardened invocation and only in a throwaway no untrusted process has written (section 5.3, review-respond). **`extract`** copies listed files out of a throwaway (and deletes listed files) into another directory under the no-follow rules review-respond's confirm relies on (section 20, review-respond).
  - **Adopted worktrees and holders.** `adopt <path> --holder <h>` records a worktree wtctl did not create (e.g. agent-spawn's `--worktree <path>`), so it gets a baseline, and adds `h` to the record's holders; removing an adopted worktree is human-only, so automation gets exit 13 (`confirmation_required`), and `status` reports it with `human_required: true`. Any worktree record, owned or adopted, can carry holders (`create --holder <h>`, `adopt --holder <h>`); `remove` refuses a record with a holder other than the one passed as `remove --holder <h>` (`reason: held`). `forget --holder <h>` removes that holder and drops an adopted record (without touching disk) only when it removed the last holder; owned records are never forgotten this way, and a plain `forget` is a human action (wtctl's `docs/interface.md`, sections `adopt`, `forget` and `remove`).
  - **Credentials** for network git operations come from `hosts.<host>.token_env` or a configured `hosts.<host>.token_command` (section 13.3), or from the SSH agent. `export` prints wtctl's audit or log records as JSONL.
  - Hooks: `pre-create`, `post-create`, `pre-remove`, `post-remove`, `post-reconcile`, `post-baseline-accept`.

#### termctl

Terminal placement. tmux backend.

- Commands: `open [--name] [--cwd] [--env] [--label k=v] [--placement] [--keep-on-exit] [--focus] [--actor] [--decision-id] [--override-escalation] -- <argv>`, `show`, `exists`, `list [--label k=v]`, `rename`, `mark <id> <marker>`, `unmark`, `focus`, `close [--force] [--override-escalation]`, `label add/remove`, `placements`.
- Uses: `tmux` (3.2 or newer).
- Notes: termctl's `docs/interface.md` is the single normative source for its rules.
  - Knows nothing about Claude. Callers say what to open (argv, cwd, name, labels); **termctl owns placement**: named placements and rules matched on the given labels in its own config decide the session and window (v1: one shared session, a window per object, QRT-4), and explicit flags override them.
  - `open` returns an id (`tc-` + 8 base32 characters) naming the pane it created, plus the resolved `socket_path`; callers store both and address the pane only by id, passing `--socket` back. Display names stay friendly and need not be unique. termctl keeps no database: its data lives in tmux pane options.
  - Status markers are named (`mark <id> attention` / `unmark <id>`); termctl's config maps a marker name to its displayed text.
  - Names are trusted input: callers build them from trusted data (e.g. a ticket key), never from third-party text.
  - The command runs directly from argv, never through a shell. A window gets the tmux server's environment plus `PATH` from the caller's filtered environment; `--env` is for non-secret values only. Outside tmux (e.g. under cron) it targets the default tmux server socket (configurable) and creates the session if it is missing; a server it starts gets an allowlisted environment.
  - `close` refuses a pane whose command is still running (exit 20, `reason: running`; termctl's own reason, distinct from the shared `live`) unless a human passes `--force` (accepted only from a TTY or with `--actor human:<user>`), which escalates SIGTERM and SIGKILL to the exact recorded PID (section 3.4). It kills only the managed pane; panes a user added to the window are never killed.
  - Hooks: `pre-open`, `post-open`, `pre-close`, `post-close`.

#### claude-session

Runs and supervises Claude Code sessions. Terminal-agnostic: it builds and runs the command; the caller decides where. Explicitly Claude-specific: it is the one implementation of the agent session role (section 3.5); higher tools treat it through that role, so another vendor's session tool can plug in later through an adapter (binding C). Its env prefix is `CSESSION_` (design guide section 5).

- Commands: `exec` (the session wrapper around `claude`), `start` (allocates a session, or with `--resume` prepares a resume, and prints the `exec` command line for a caller to place), `resume`, `stop`, `report`, `status`, `wait`, `list`, `kinds`, `label add/remove`, `forget`, `reconcile`, `transcript`, `export` (audit records), `cron install|uninstall`; internal: `hook-event --state-dir <dir> <event>` (called by the hooks it injects into sessions), `verify-secret <csession_id>` (checks a session secret given on stdin, section 8.3).
- Uses: `claude`; optionally memoctl for session-start context (binding B, `notes_context_cmd`; enabled per kind with `notes_context: true`).
- Notes: `--kind <name>` selects a kind profile from this tool's config. Standalone, it records state and exits with an outcome code; post-exit policies (auto-resume, promotion, parking) belong to agent-spawn. Auto-exit after `report done` is performed by `exec` itself. See section 8 for the full session model. Supports labels on sessions for standalone use; for agents, agent-spawn is the authoritative label store and mirrors agent labels onto the session. Records taint (section 8.5).
- Hooks: `pre-launch` and `post-state-change` (fired by `exec`, section 8.2).

#### jobsctl

Generic job queue. Owns the concurrency caps (used for "max parallel agents") and the order of work already enqueued (QR-9); it does not interpret what jobs do.

- Commands: `add [--queue Q] [--unique-key K] [--priority N] [--cwd P] [--env VAR=value] [--pass-env VAR] [--label k=v] [--timeout D] [--wait] -- <argv...>`, `list`, `show`, `wait`, `move`, `pin`/`unpin`, `priority`, `hold`, `release [--override-escalation]`, `resolve [--as done|failed|canceled]`, `cancel [--force]`, `retry`, `label add/remove`, `capacity [--queue Q] --json`, `queues`, `run [--loop]` (runner), `reconcile`, `prune`, `export`, `cron install|uninstall`, `browse`.
- Uses: none.
- Notes: jobsctl's `docs/interface.md` is the single normative source for its rules.
  - Jobs are stored as argv arrays (no shell). A job's argv never contains untrusted text; submitters pass such text in files. A job runs with **jobsctl's base environment**: allowlisted variables (configurable; `TMUX` and `SSH_AUTH_SOCK` are not inherited by default), fixed config values, `add --env VAR=value` (non-secret values only; they are stored; values that contain a known secret are refused) and `add --pass-env VAR`. The allowlisted values still come from the process that started the trigger chain (cron, a shell, a finishing shim); only the env file and fixed config values are the same whichever process triggered the pass, so a stable `PATH` is set in config, where it also replaces the inherited `PATH` of hooks and of jobsctl's own processes (jobsctl drops empty, relative, non-existent and temporary `PATH` entries). A `--pass-env` value comes from the user-owned env file that every pass and shim loads, never from the submitter; it is read when the job starts and never stored, and if the file does not define it the job fails with reason `missing_env`. jobsctl reads its config only from files (no `JOBSCTL_*` config variables). The env file is a trust anchor (its values reach running code as the user): it and its ancestor directories must be owned by the user or root and not writable by others, and it must lie, like jobsctl's config and state, outside every path an isolated session can write; its values never enter jobsctl's own environment (only hooks and, through `--pass-env`, jobs get them), and its lines cannot change a hook's `PATH`, loader or shell startup. Each job gets `JOBSCTL_JOB_ID` (unchanged across retries) and `JOBSCTL_ATTEMPT`.
  - Named queues, created on first use with a default cap of 1 and configured per queue; within a queue, pins, then priority, then position (`move`); across queues, queue priority, then the oldest waiting job. Per-queue caps plus an optional `global_cap`. The workflow tools submit to the queues `tickets`, `reviews` and `respond` by default (configurable in each submitting tool); `global_cap` bounds the total number of parallel agents. `capacity` reports free slots per queue (cap − running − queued, where jobs whose `pre-start` hooks run count as running) and `effective_free` (the smaller of the queue's and the global free slots, where the global count includes only queued jobs that could start under their own queue's cap); callers deciding whether to enqueue use `effective_free`.
  - `add --unique-key <key>` is a no-op (exit 0, returning the existing id) if a non-terminal job has that key, in any queue; held jobs are non-terminal. Callers use keys such as `review:<pr>@<sha>`, `respond:<pr>`, `ticket:<KEY>`.
  - **Runner and shims.** `jobsctl run` is one short pass (cron or `run --loop`): it claims jobs up to the caps and starts each under its own detached shim, which runs the `pre-start` hooks while holding the job's slot, starts the job and records its outcome. `add`, a finishing job and the commands that can make a job startable (`cancel` of a starting job, `release`, `retry`) trigger a pass early (concurrent triggers coalesce), so cron is a safety net.
  - Statuses: `queued`, `starting`, `running`, `held`, `done`, `failed`, `canceled`; terminal statuses carry a reason, held jobs a hold reason. Job exit → status: 0 → done; 13 → **held** (its slot is freed); any other exit → failed. A `pre-start` hook veto (any non-zero exit other than 13) → canceled (`vetoed`); a `pre-start` hook escalation (exit 13) → held. A job ended by a SIGTERM that was not a `cancel --force` (e.g. shutdown or logout) → failed (`terminated`). No automatic retry by default (opt-in per queue); a job waiting for an automatic retry stays `queued` (with a not-before time and its unique key) rather than failed. `retry` requeues the same job id as a new attempt. `wait <id>` exits 0 done, 12 failed, 13 held, 20 canceled.
  - **Held jobs.** `resolve <id> [--as done|failed|canceled]` closes a held job. `release <id> --override-escalation` (human only: a TTY or `--actor human:<user>`; audited) requeues a job held by a `pre-start` escalation, and its next start treats the escalating hooks as allowing. A job held because its own command exited 13 (e.g. an agent that needs a human) is never released: its submitter resolves it and continues through `agent-spawn resume` (section 9.3), or requeues it under the same id with `retry` (the held attempt stays recorded; no terminal hook fires). Job commands that launch agents are therefore resume-aware: they look for an existing agent by its `job=` or correlation labels and resume it instead of launching a second one.
  - **Cancel.** `cancel` of a queued, held or starting job closes it as canceled. `cancel` of a running job is refused (exit 20, `reason: live`) unless a human passes `--force`, because a running job may host a live interactive agent. With `--force` the shim (or, for a job whose shim died, a detached jobsctl helper) sends SIGTERM to the job's exact PID, which every layer below forwards (section 9.2); if the job or processes in its process group remain after a grace period, the shim (or, after a shim loss, the helper) signals the job's process group (SIGTERM, then SIGKILL). The shim created that group for the job, so this is the only group signal besides hook groups (section 3.4). A configured job timeout ends a job the same way.
  - Stores exit status and a masked, sanitized tail of each job's combined output (`show <id> --json`, 16 KiB by default). Tails mask the values of the env vars listed in config `mask_env`, of every `--pass-env` variable and of every variable in the env file, and are documented as untrusted. Masking is best-effort (jobsctl's Residual risks): secrets a job obtains itself are not masked. Hook output is not stored; only a veto's or escalation's message is kept on the attempt and a short masked excerpt of a failing hook's stderr is logged.
  - `reconcile` (and every pass) checks shims and jobs by PID, process start time and boot id: a job whose shim and process are gone is finalized from the result file its shim wrote, if any, else marked failed (`lost`, firing `post-fail`), or canceled (`forced`, firing `post-cancel`) when a force request was committed; a job whose shim died but whose process lives keeps its slot and is never killed automatically.
  - Hooks: `pre-start`, `post-start`, `post-finish`, `post-fail`, `post-held`, `post-cancel`; a hook receives the job's output tail only if its config opts in. Supports labels; submitters label jobs with the same correlation labels they give the agent. Audits `cancel --force`, cancels of held jobs, `release --override-escalation`, `resolve`, `retry` and `prune`.

#### gatectl

Policy decisions with first-class shadow mode.

- Commands: `check <policy> [--input <file> | --input -] [--timeout <seconds>]`, `outcome <decision-id> agree|disagree`, `decisions --json [--since <time>]`, `stats`, `set <policy> off|shadow|enforced`, `policies`.
- Uses: claude-session (agent checks, headless, kind `gate-check`); ships `plugin/` with its default agent-check skills.
- Notes: `check` reads the input JSON from the file given, or from stdin when `--input` is `-` or absent (exit 2 if absent and stdin is a TTY). It exits 0 allow, 11 deny, 13 escalate, and prints JSON on stdout including `decision_id`, `decision`, `state`, `shadow` and `enforced`. Policy states and shadow mode are described in section 12.3. A policy is a named, ordered list of checks: deterministic scripts (JSON on stdin → exit code/JSON) and agent checks (a Claude skill returning decision + confidence, with a threshold). Combination and miss handling are in section 12.3. Policies declare their expected input; they are global with per-repo overrides keyed off the input's `repo`. Every decision is audited.

#### memoctl

Uncommitted shared knowledge for agents: things other agents may need to know that should not be committed.

- Commands: `add --body-file <path>|-`, `list`, `show`, `search`, `context --repo <repo-id> [--label k=v]...`, `prune`.
- Uses: none.
- Notes: Keyed by repo and topic, with labels. Each note records a *claimed* author kind read from the env var named by config `kind_env` (default `CSESSION_KIND`; best effort, spoofable). A missing value is recorded as `kind=unknown`, which is treated like a third-party-reading kind (section 13.2 rule 8). `context` emits a compact, fenced block suitable for injection at session start (QR-19); by default it excludes notes whose claimed kind is third-party-reading or unknown.

#### slack-notice, ha-notice, desktop-notice

One small tool per channel: `send --stdin-json` (a JSON object with `title`, `message`, `level`, `link`) or, for trusted human use, `send --title ... --message ... [--level info|warn|action|error] [--link URL]`. Levels are ordered `info < warn < action < error`.

- Uses: curl/HTTP (desktop: the platform's native notifier).
- `slack-notice`: Slack incoming webhook; the URL comes from the env var named by config (`webhook_env`).
- `ha-notice`: Home Assistant REST notify service (base URL and service name from config; token from the env var named by `token_env`).
- `desktop-notice`: native notification; on WSL, a Windows toast (nice-to-have).
- All channel tools escape platform markup in title and message (no mentions, no link injection); links are only added via `link`/`--link`.

### 5.2 Layer 2: composites

#### pr-watch

Watches PRs for changes.

- Commands: `watch add <pr> [--label k=v] [--owner <tool>]`, `watch add --mine --open [--owner <tool>]` (query watch), `watch remove (<pr> | --mine --open) [--owner <tool>]`, `poll`, `list`, `events [--label k=v] [--pr <ref>] [--since <cursor>]`.
- Uses: forgectl.
- Notes: Detects new commits, comments, reviews, approvals, CI changes, readiness and merge/close. Event types include `comment`, `review_comment`, `review`, `approved`, `changes_requested`, `ci`, `ready`, `merged`, `closed`, `pushed`. Exposes `on-<event>` hooks per change type (e.g. `on-comment`, `on-approved`, `on-merged`); these report external changes and cannot veto. Watches are reference-counted by owner: `watch add --owner <tool>` adds that owner's reference, and `watch remove --owner <tool>` removes only that owner's reference. `events` is non-destructive: each consumer keeps its own cursor, an opaque string; without `--since`, events start from now. A cursor older than the retention window returns exit 0 with `"gap": true`; the consumer then re-syncs current state through forgectl and resets its cursor. Used by review-watch, review-respond, ticket-work and the harness.

#### pr-comment

Posts to PRs.

- Commands: `review --draft-file <path> [--approve] [--reanchor-to <sha>]`, `reply --body-file <path>|-`, `comment --body-file <path>|-`, `resolve`, `approve`.
- Uses: forgectl.
- Notes: Defines the review-draft format in its `schemas/`. `review` posts as COMMENT (or REQUEST_CHANGES when the draft says so) unless `--approve` is passed. `review`, `approve`, `reply` and `comment` are confirm-by-default with no pending store (section 12.4). Checks the PR head SHA before posting and refuses on a mismatch (exit 20, `reason: stale_head`). Owns re-anchoring: `review --reanchor-to <sha>` moves findings onto a new head, and findings that cannot be re-anchored move to the review body. Appends attribution footers containing the marker `<!-- pr-comment:v1 -->` (section 14). Writes audit records. Nothing passes `--approve` or calls `approve` automatically by default.

#### ticket-queue

"Which ticket should I do next?"

- Commands: `refresh`, `list`, `next [--claim]`, `claim KEY`, `release KEY [--failed]`, `why KEY`, `pin`, `move`, `skip`, `browse`.
- Uses: ticketctl; claude-session (default re-rank, headless, kind `rank`); ships `plugin/` with the rank-tickets skill.
- Notes: Candidate pool from configured boards/filters, refreshed periodically, ranked by the pipeline in section 11. Orders candidates not yet started (work already enqueued is ordered by jobsctl). Pins and manual moves always win. **Claims:** `next --claim` and `claim KEY` reserve a ticket so it is not handed out twice; `claim` on a ticket already claimed renews it. A claim is held until `release`; a TTL applies only to claims that are not renewed. `release KEY --failed` records a failed start; after N consecutive failed releases the ticket is auto-skipped and a hook fires (section 20).

#### ticket-create

Skill-wrapper: draft and create tickets.

- Commands: `draft`, `create`.
- Uses: ticketctl, agent-spawn (same layer; allowed by section 3.2).
- Notes: Default mode interactive; `draft` runs the session (kind `draft-ticket`) in the current terminal (`--placement here`). `create` requires a TTY (exit 13 otherwise) and always confirms before creating. The draft-ticket skill and template are configurable (an organization's ticket format lives in the user's config or skill, not here).

#### notice-route

Routes notifications to channels.

- Commands: `send`, `rules`, `test`, `flush`, `history --json`.
- Uses: any configured notifier command (ours or third-party, via adapters).
- Notes: `send --stdin-json` reads either a hook payload (mapped to title and message by rule templates) or the channel-tool JSON shape; it takes `--source <tool>` and repeatable `--label`. Plain `--title`/`--message` remain for trusted human use. It always calls channel tools with `send --stdin-json`. Rules match on level, source, labels and time and fan out to channels. Level order, quiet hours and dedup are in section 15 and section 20; deferred notifications are delivered by `flush`.

#### agent-spawn

Launch, resume, park and tear down agents: worktree + terminal + Claude session.

- Commands: `launch`, `resume`, `list [--label k=v] [--needs-attention]`, `show`, `attach`, `ack <agent_id>`, `label add/remove`, `teardown`, `prune`, `reconcile`, `browse`; internal: `supervise`.
- Uses: claude-session; termctl (interactive window placement only); wtctl (only when a worktree or a local clone is needed).
- Notes: Flags and defaults are in section 9.2. Authoritative label store for agents. Owns post-exit policies through its supervise wrapper. Does not use jobsctl. Never notifies directly: it records attention as data (`needs_attention`) and fires hooks (`post-escalate`, `post-park`, `post-state-change`). Agent lifecycle is separate from window lifecycle (section 9). Its worktrees carry wtctl's repo-config baseline (section 13.2 rule 10); it reports `repo_config_changed` in `show --json` from `wtctl baseline check`. `resume --fork` records the fork as a new agent (section 9.4).

### 5.3 Layer 3: workflows

#### review-run

Skill-wrapper: run a review skill on a PR.

- Commands: `run <pr> [--skill ...] [--mode ...] [--label k=v]`, `list [--label k=v] --json`, `show <run> --json`.
- Uses: forgectl (pre-fetch), wtctl and `git` (throwaway checkouts, only when `run_pr_code: true`; binding A), agent-spawn, pr-comment (review-draft schema only; binding A).
- Notes:
  - Default mode headless. The session is always launched with `--kind review`, `--worktree none` and its cwd in `$CSESSION_DIR/work/`; it never has a checkout. review-run pre-fetches the diff and metadata so the session needs no git-host credentials, and passes the review safety settings per call (section 13.1). `run --label` values pass through to the agent.
  - Stores runs and its own copy of their artifacts; run states are `running`, `done`, `escalated` and `failed`, and `show` refreshes from agent-spawn for escalated or promoted runs. The artifact is pr-comment's review-draft format plus metadata (verdict, severities, model-reported risk); it is immutable once stored. A run whose artifact is missing or fails the review-draft schema is `failed` (an implicit-done `result.md` is not a review draft).
  - Tears down its review agents (`owner=review-run`) only when the run is `done` or `failed`; an `escalated` run keeps its agent until it is resolved.
  - With per-repo `run_pr_code: true`, runs the throwaway-checkout sequence before the session starts (section 13.2 rule 9).
  - Ships a generic default review skill; config can point at any other review skill. Never requests env-file copying.

#### review-watch

Watches for review requests, runs reviews unattended and holds each result as a draft you accept.

- Commands: `poll`, `list`, `show <id>` (a queue item), `accept <id> [--reanchor|--dry-run]`, `reject <id>`, `rerun <id>`, `status` (summary of the queue and today's runs, plus gate track records from `gatectl stats` when gatectl is configured), `logs <id>` (run log), `browse`.
- Uses: forgectl, review-run, pr-comment; optionally pr-watch, gatectl and jobsctl.
- Notes:
  - The behaviors below (direct-request trigger, skips, risk tiers, shadow mode, staleness, round limit) are generic design decisions of this project; prior art is cited in review-watch's design doc.
  - Considers only PRs that request your review directly; team-level requests are ignored. Skips draft PRs, bot-authored PRs and PRs you already reviewed yourself (a review by your own account carrying the `<!-- pr-comment:v1 -->` marker was posted through awkit and does not count).
  - Keys its queue items on (PR, head sha, review-request instance) and enqueues only for a new item. It runs `review-run run <pr> --label rw-item=<id>` via jobsctl (queue `reviews`, `--unique-key review:<pr>@<sha>` as a second safety net) or, without jobsctl, as detached processes; `poll` never blocks on a review. `poll` resolves held review jobs once the run is done or failed, or the item is rejected.
  - Copies the review-run artifact into its own review draft, which is the editable, authoritative copy for posting. Marks review drafts stale when the head moves; `accept --reanchor` re-anchors through `pr-comment review --reanchor-to <sha>`. `accept` is a human action and passes `--yes --actor human:<user>` to pr-comment.
  - New commits never start a review on their own; a fresh review request or an explicit `rerun` does, up to a configurable per-PR round limit.
  - **Risk tier** is computed deterministically from PR facts (paths, size, author, repo rules, CI); model output can move a PR to a stricter tier, never a looser one. Auto-post and auto-approve go through gatectl (shadow first, section 12.3); an auto-approve policy must include a script check that ignores model output. It passes `--approve` to pr-comment only when an enforced auto-approve gate allows and the hard rules pass.
  - **Built-in hard rules** (the public minimum, applied regardless of gate decisions): never auto-approve your own PRs or bot PRs; never auto-post or auto-approve unless CI has passed on the PR's current head; never auto-act on a PR that touches an off-limits path (a configurable glob list whose default covers security-sensitive code, CI and build pipeline definitions, agent configuration and instruction files, and review-ownership files).
  - **Gate outcomes:** when you act on a gated item, it records `gatectl outcome <id> agree` if your action matches the gate's (would-be) decision and `disagree` otherwise (e.g. the gate would auto-post and you edit or reject the draft).
  - Has an internal concurrency cap so it works without jobsctl; its built-in hard rules let it work without gatectl. Optional daily spend cap, off by default (section 20).
  - Hooks (indicative): `post-draft`, `post-pending`.

#### review-respond

Respond to review comments on your PRs.

- Commands: `check`, `respond <pr> [--skill ...] [--mode ...]`, `list`, `pending`, `confirm <id>` (alias `approve`), `reject <id>`.
- Uses: pr-watch, forgectl, agent-spawn, pr-comment, wtctl (throwaway checkouts and `extract`), `git`; optionally jobsctl (without it, runs its job command directly under an internal cap); optionally gatectl (auto-push / auto-reply decisions).
- Notes:
  - "Your PRs" are PRs authored by the user. Only comments from repo collaborators with write access or from configured reviewers trigger a respond; other comments notify only. Ignores the user's own comments by default (opt-in: `respond_to_own_comments_prefix: "/awkit"`), comments carrying the `<!-- pr-comment:v1 -->` marker on content from the user's own account, and configured bot authors. All comment text is untrusted and fenced.
  - `check` ensures that the query watch `pr-watch watch add --mine --open --owner review-respond` exists, reads events since its own cursor, keeps a per-PR comment watermark, and resolves held respond jobs.
  - Finds the agent with `agent-spawn list --label pr=<pr> --json`. If several agents match, it prefers its own respond agent (`owner=review-respond`: an earlier fork or a fresh session), then the one whose `owner` label equals config `prefer_owner` (default `ticket-work`), else the most recent. It does not enqueue while the original agent or its respond fork is live.
  - **Forked respond sessions.** The first respond round on an agent it does not own resumes it with `--fork` (section 9.4): Claude Code forks the conversation (`claude --resume <id> --fork-session`), the fork becomes a new respond agent labeled `pr=<pr>` and `owner=review-respond`, and the original implement session never receives untrusted comment text. Every later round forks the previous round's respond fork the same way (`--fork --cwd <new throwaway>`), never a plain resume: a plain resume always keeps the previous run's cwd (claude-session's rule), which is the previous round's removed throwaway. Each round's fork becomes the PR's current respond agent; earlier forks are parked. Forks are tainted (section 8.5) and torn down when the PR is merged or closed (they never own a worktree).
  - **Disposable checkout per round.** Every respond round runs in a throwaway checkout that review-respond creates for it (`wtctl create --throwaway --ref <PR head sha>`, a separate disposable clone, as review-run uses in section 13.2 rule 9), never in the user's real worktree. The fork is launched there with `--fork --cwd <throwaway>` (section 9.4), every later round forks the previous respond fork into its own new throwaway, and fresh respond sessions are launched there likewise; the prompt tells the agent its working copy path (the forked conversation mentions the original worktree's paths). wtctl itself never runs git in a throwaway after creating it. A caller may run git in a throwaway only with the hardened invocation (section 13.2 rule 10), and only in a throwaway no untrusted process has written (review-respond's clean checkout for confirm, below); no trusted process runs anything in a throwaway an agent has touched. (claude-session's hardened, read-only git-dir resolution at launch is a hardened read, not a command run in the agent's checkout on its behalf.) review-respond removes the throwaway checkout after `confirm` or `reject`; a fork agent never owns it.
  - One job per PR (queue `respond`, `--unique-key respond:<pr>`). The job runs review-respond's internal job command, which creates the round's throwaway checkout and runs `agent-spawn resume <agent_id> --fork --label pr=<pr> --label owner=review-respond --cwd <throwaway> --kind respond --prompt-file <fenced "new review comments" file> --permission-profile <bundled file> --sandbox required --setting-sources "" --env-allowlist-only <var> ... --wait`, then records the pending confirmation and marks the delivered comment ids handled. Comments are **delivered** once the resumed session reached `working`. The prompt file contains only comments whose author passes the trigger eligibility check above; other comments are never shown to the session.
  - The respond session cannot push, commit or write to the git host: its required sandbox has no network, its git directory is read-only (section 13.1), and the respond profile also denies `git push` and `gh`/`glab` as defense in depth (public default). The agent only edits files in the throwaway checkout, without staging, and reports an artifact `{"replies": [{"comment_id", "body"}], "changed_files": ["<path>", ...], "deleted_files": ["<path>", ...], "commit_message": "..."}` (review-respond owns this contract; claude-session's interface lists it as the respond slot's expectation), which becomes a pending confirmation recording the PR head sha of the round. `confirm <id>` copies only the files listed in `changed_files` (and removes those in `deleted_files`) from the throwaway checkout into a clean checkout with `wtctl extract`: a second, fresh throwaway at the PR head (`wtctl create --throwaway --source remote --ref <PR head sha>`, fetched by sha over the clone fetch URL unless `repos.<id>.clone_url` overrides it, never from the clone's objects) that no agent ever touches (validated paths, regular files with one link only, every component opened without following links, size-capped; the normative rules are in wtctl's `docs/interface.md`, section Extraction rules; the user's real worktree is never written by a session that read third-party text), commits them with the user's own git identity through hardened git outside the sandbox (section 13.2 rule 10; the message is the agent's, shown to the user before confirming and treated as untrusted), pushes fast-forward only to the PR head ref (audited) from the clean checkout, to the clone fetch URL (`wtctl locate --json`, `fetch_url`), posts the replies via pr-comment, and removes both throwaways; `reject <id>` removes the round's throwaway too. The recipe is in wtctl's `docs/interface.md`, section Extraction rules (clean checkout for confirm). If the remote head moved, the confirmation stays pending with `reason: remote_moved` (exit 20).
  - **Auto-push and auto-reply** (opt-in) are automatic actions: they require an enforced allowing gate (section 12.3) and these built-in hard rules: never push a diff that touches the off-limits paths (the same default list and format as review-watch's, configured in each tool), and never push unless CI on the previous PR head is green. Otherwise the pending confirmation stays for the user.
  - Fresh sessions (no original agent) only for opted-in PRs (`repos.<id>.respond_fresh: true` or a PR label), never for PRs from forks. They run in the round's throwaway checkout (`--cwd <throwaway>`), are labeled `owner=review-respond`, and are torn down when the PR is merged or closed.
  - Respond rounds per PR are capped (`max_rounds`, default 3), then it escalates.
  - Hooks (indicative): `post-pending`.

#### ticket-work

Owns the lifecycle of a worked ticket (QR-16).

- Commands: `start [KEY] [--auto] [--skill ...] [--mode ...]`, `sync`, `list`, `stop <KEY>`, `pending`, `confirm <id>`, `reject <id>`.
- Uses: ticketctl, ticket-queue, forgectl, pr-watch, agent-spawn, wtctl, jobsctl.
- Notes:
  - `start` with no key takes `ticket-queue next --claim`; with a key it runs `ticket-queue claim KEY`.
  - **Transitions are applied at confirm time.** From a TTY, `start` shows and confirms the assignment, sprint and transition, applies them (`ticketctl ... --yes`), then enqueues. A non-interactive `start` (e.g. `--auto` from cron) records a pending confirmation and does not enqueue; `confirm <id>` applies the changes and enqueues. Setting `auto_transition: true` in config removes the confirmation. `start --auto` enqueues only while `jobsctl capacity` is above 0, counts unresolved pending starts against that capacity, and records at most one pending start at a time (unless `auto_transition: true`).
  - Jobs use queue `tickets` and `--unique-key ticket:<KEY>`. The resume-aware job command launches an interactive implement agent (kind `implement`) labeled `ticket=KEY` and `owner=ticket-work`. If the job fails to launch the agent, ticket-work restores the previous ticket status, releases the claim with `--failed`, and fires `post-start-failed`.
  - `sync` renews the claims of in-flight tickets and releases them when work ends. It links PRs to tickets (section 20), adds the `pr=` label via `agent-spawn label add`, adds a pr-watch watch (`--owner ticket-work`), writes an audit entry, and applies the per-board **status map** to events `pr_opened` (including draft), `pr_ready`, `pr_merged`, `pr_closed_unmerged`, `agent_blocked`, `agent_failed`. Every run checks the current state of linked PRs via forgectl; `pr-watch events --since <own cursor>` provides early detection. Closed-unmerged default: notify, no transition, no teardown. `sync` also resolves held ticket jobs; the agent itself continues through `agent-spawn resume`.
  - `stop <KEY>` exits 20 (`reason: live`) if the agent is live (it never ends a live session). Otherwise it leaves the agent parked and the worktree in place, releases the claim, and applies an optional transition per the status map. Removing the worktree is a separate teardown (`agent-spawn teardown`; a human passes `--force` if the work is unmerged).
  - Organization rules (e.g. "needs story points to leave backlog") are per-board preconditions in config. Fully standalone via cron; the harness only triggers `sync` early.
  - Hooks (indicative): `pre-enqueue`, `pre-transition`, `pre-launch`, `post-link`, `post-status`, `post-start-failed`, `post-pending`.

#### session-audit (post-v1)

Skill-wrapper: analyze transcripts and outcomes; retros ("what went well / badly"); usage analytics. Default mode headless.

#### self-improve (post-v1)

Skill-wrapper: turn audit findings into proposed edits to skills, CLAUDE.md files or config, presented for acceptance. Default mode interactive.

### 5.4 Layer 4: the harness, awkit

See section 7.

### 5.5 Capability slots (skills)

Skills are the model-driven part of a workflow. Each slot has a default skill bundled in the `plugin/` of the tool that uses it, and can be pointed at any other skill in config (QG-4, QR-20). A skill name is whatever Claude Code accepts as a slash command: `plugin:skill` for plugin skills (bundled defaults are `<tool>:<skill>`), bare names for user or project skills.

| Slot | Used by | Kind | Default mode |
|---|---|---|---|
| review-pr | review-run | `review` | headless |
| implement-ticket | ticket-work (via agent-spawn) | `implement` | interactive |
| respond-to-review | review-respond | `respond` | the original agent's mode when resuming (as a fork); headless for a fresh session |
| draft-ticket | ticket-create | `draft-ticket` | interactive |
| rank-tickets | ticket-queue (optional model re-rank) | `rank` | headless |
| gate-check | gatectl | `gate-check` | headless |
| audit / improve | session-audit / self-improve (post-v1) | `audit` / `improve` | headless / interactive |

The **skill-wrapper tools** are review-run, ticket-create, ticket-work (implement), review-respond, session-audit and self-improve; each offers `--skill` and `--mode` (design guide section 11). Tools whose skill step is internal and headless-only (gatectl agent checks, ticket-queue re-rank) are exempt from `--mode` and configure their skill in config.

In-repo documentation updates are part of the implement-ticket skill, which also enforces the draft-PR public default; a separate update-docs slot was dropped (QR-19). The ticket source is a tool role (ticketctl), not a skill slot.

## 6. Conventions (summary)

The full conventions are in `design-guide.md`. In brief:

- CLI: stdlib `argparse`; human output by default, `--json` for machines. Reserved exit codes across all tools: 0 success, 1 unexpected or internal error, 2 usage, 10 not found, 11 vetoed/denied, 12 the requested operation failed for an expected, reportable reason (for launch/resume: the session was never started), 13 needs a human (escalated, held or pending confirmation), 14–19 session outcomes (section 8.3), 20 refused, with a JSON `reason` (`live`, `dirty`, `unpushed`, `stale_head`, `remote_moved`, `repo_config_changed`, `tainted`, ...), 21 ambiguous selector, 22+ tool-specific.
- Config: YAML at `~/.config/<tool>/config.yaml` plus drop-in files `~/.config/<tool>/config.d/*.yaml` merged after it, validated with Pydantic; env vars `<TOOL>_<KEY>`; precedence: flags > per-repo override > environment variables > global config > built-in defaults (per-repo outranks env on purpose, so a global env setting cannot silently override a repo's safety settings). The current repo is `--repo`, else the input object's repo, else the cwd's `origin` remote. Tools that need "me" read `me: {name: ..., github: ..., gitlab: ..., jira: ...}`, falling back to the CLI's logged-in user (`me.name` defaults to the OS username).
- State: SQLite (WAL) under `~/.local/state/<tool>/`; paths respect XDG and are the same on macOS. `state.db` is private; `log.jsonl` and `audit.jsonl` are public, append-only contracts (`schemas/log.json`, `schemas/audit.json`) that other tools may read and watch.
- Credentials: environment variables only, named in config (`token_env`).
- Hooks: `pre-<step>`/`post-<step>` (and `on-<event>` for detected external changes), JSON on stdin, run via `sh -c` in their own process group with no template substitution; a pre-hook exiting 13 escalates, and any other non-zero exit vetoes (the tool exits 11); timeouts; optional async post-/on- hooks; per-invocation `--hook <name>=<cmd>` where supported.
- Labels: `--label key=value`, a stored multiset, filterable; no tool assigns built-in meaning to a key.
- Identifiers: repo `host/<full project path>`; PR by URL or `host/<full project path>#N` (section 3.4).
- Untrusted or agent-generated text is accepted only as `--<name>-file <path>` or `-` (stdin), never only as an argv string.
- Concurrency: commands invoked by cron or the harness are safe under concurrent invocation (per-object lease locks in `state.db`; a second caller exits 0 reporting "already running").
- Audit: every external-action command accepts `--actor` and a repeatable `--decision-id`.
- Confirm-by-default actions reached without a human become pending confirmations or exit 13; automation never passes `--yes` to bypass them (section 12.4).
- TUIs: optional `browse` subcommand (Textual), `--focus`, `--result-file`.
- Schemas: `schemas/` in each repo documents `--json` outputs, hook payloads, config, audit and log records.
- Untrusted text is fenced with nonce-tagged blocks and never passed in argv or env (section 13.2); attribution footers carry the `<!-- pr-comment:v1 -->` marker; audit log per tool.

## 7. The harness: awkit

`awkit` is the only component aware of the others. It is optional: everything else works without it.

### 7.1 Tool registry and adapters

- `awkit` reads a **tool registry** from its config (`~/.config/awkit/config.yaml`) listing which tool fills each **role**, e.g. `roles: {githost: forgectl, tickets: ticketctl, notify: notice-route}`. (This is distinct from the **interface registry** in `awkit-docs`, section 18.3.)
- Each registered tool has an **adapter** describing how `awkit` talks to it (QR-4):
  - **Declarative YAML first:** command templates (e.g. `list: "jobsctl list --json --queue {queue}"`), jq/JSONPath mappings from tool output into the harness model, trigger definitions, and `periodic:` declarations (commands that should run on a schedule, section 7.7).
  - **Escape hatches:** any single operation, or a whole adapter, can instead be a Python function or an external executable speaking a harness-defined stdin/stdout JSON protocol. This protocol belongs to the harness; tools never see it.
- Adapters for our tools and common third-party CLIs ship in the `awkit` repo. A user overlay at `~/.config/awkit/adapters/` adds or overrides adapters (e.g. a private adapter pointing a role at an employer-internal tool). Tool repos never mention the harness (QR-5).

### 7.2 Process model: tick and run

- `awkit tick` does one unit of work: poll adapters that are due, diff their snapshots against the last ones, derive harness events, update the state graph, and evaluate rules (QR-1).
- Cron runs `awkit tick` periodically (interval in awkit config, default 1 minute).
- `awkit run` (and the dashboard while open) loops `tick` at short intervals and accepts early-tick triggers:
  - per-adapter poll intervals;
  - file watchers on a tool's public files (`log.jsonl`, `audit.jsonl`) or other paths an adapter declares (only while the loop runs; note the WSL `/mnt/c` caveat). A watch is purely a trigger for an early poll; data is still read via the tool's CLI;
  - pushes: tool hooks wired to `awkit notify-tick` (section 7.3), e.g. agent-spawn's `post-state-change`.
- **Tick lock:** the lock is held for one tick only. Several loops may coexist (cron, `awkit run`, an open dashboard); at most one tick executes at a time, and the others serialize. A dashboard opened while `awkit run` is active still runs its own loop.
- **Idempotency:** ticks are idempotent with respect to state; anything missed is caught by the next poll. Rule actions are recorded (with the event id) before execution, with their result after, and skipped if already recorded; a failed action is retried up to N times (configurable). Rule actions run detached or via jobsctl and never block the tick. Events are internal to `awkit` and are never required by tools. Because the harness is optional, every workflow keeps its periodic cron fallback (section 7.7) even when rules trigger it early.

### 7.3 Wiring hooks

`awkit wire <tool>` shows the exact hook registrations that would let that tool call `awkit` (e.g. "on `on-merged`, run `awkit notify-tick --source pr-watch`") and applies them on confirmation; `--yes` skips confirmation; `awkit unwire <tool>` reverses it. `awkit wire` writes only the drop-in file `~/.config/<tool>/config.d/awkit.yaml`, which the tool merges after its `config.yaml` (hook lists are appended); it never edits `config.yaml`, and `awkit` never edits tool config any other way (QR-3).

Separately, claude-session injects its own Claude Code hooks into the sessions it starts. `awkit` learns about session changes primarily through tools' lifecycle hooks (and otherwise by polling): for agents, the recommended source is agent-spawn's `post-state-change` (section 9.1); claude-session's own hooks serve standalone sessions. Wiring both tools' state hooks to notifications produces duplicates and should be avoided.

### 7.4 State graph

- Nodes: ticket, worktree, agent (Claude session), tmux window, job, PR, review draft, gate decision (from `gatectl decisions --json`), notification (from `notice-route history --json`).
- Edges are derived mostly from labels on lower-tool objects (`ticket=KEY`, `pr=host/<full project path>#N`, `repo=host/<full project path>`, `kind=...`, `owner=<tool>`, `job=<id>`, `rw-item=<id>`) plus branch names. `awkit` stores only links it alone can infer (QR-11), so its state is largely disposable and can be rebuilt from tool outputs.

### 7.5 Rules

"When X then Y", evaluated on derived events. Notifications are wired directly from tools' hooks to notice-route by default (section 15), so rules do not send notifications unless the user adds such a rule. Examples:

| When | Then |
|---|---|
| pr-watch `comment`, `review_comment` or `review` event on a PR for which agent-spawn has an agent labeled `pr=` | `review-respond respond <pr>` |
| pr-watch: PR merged or closed | `ticket-work sync` |
| pr-watch: the user's PR approved, CI green, mergeable, repo opted in | `gatectl check auto-merge` (its input includes the PR head sha); only if the JSON shows `"enforced": true` and `"decision": "allow"` → `forgectl merge --yes --expected-head <the sha the gate evaluated> --decision-id <id>` (public default: notify only) |
| jobsctl: job held or failed | `review-watch poll` / `review-respond check` / `ticket-work sync` for the owning workflow, so it resolves or reports the job early |

Attention items are not rule actions; the dashboard derives them (section 7.6).

### 7.6 Dashboard TUI

- Opened with `awkit dashboard` (or `awkit` with no arguments).
- Cross-tool views only `awkit` can build: the **attention list** ("needs you"), ticket → agent → PR → review chains, and recent events. Attention items are a dashboard concept; `awkit` derives them from tool records and hooks: agents with `needs_attention` (`agent-spawn list --needs-attention`: unreported, escalated, blocked, failed, lost), held and failed jobs, review drafts awaiting accept, each tool's pending confirmations, and sessions in `needs-input`. Idle sessions are not listed.
- A launcher for the tools' own TUIs. Drilling in **suspends** the dashboard and runs the child TUI in the same pane in the foreground; the dashboard redraws with state intact when the child exits (QR-15). Targeted drill-in passes arguments such as `--focus KEY-12`. If the child supports `--result-file`, `awkit` reads the result (in the child's vocabulary) and its adapter translates the intent: e.g. `start` → enqueue work, `back` → return to the dashboard, `open` → open another TUI. Children without it just return.
- Actions from the dashboard go through the owning tool's CLI (start work, accept a review, confirm a pending action, attach to an agent, resume, acknowledge, teardown). The dashboard confirms in its own dialog and then passes `--yes --actor human:<user>`. Reorder maps to whichever tool holds the item: ticket-queue for candidates not yet started, jobsctl for enqueued work.

### 7.7 Other harness commands

- `awkit audit`: merges every tool's `audit.jsonl` into one timeline, filterable by label, PR or ticket (QSC-3).
- `awkit notify-tick [--source <tool>]`: requests an early tick and returns immediately.
- `awkit cron install|uninstall`: writes crontab entries (explicit `PATH` including `~/.local/bin`, optional user-owned env-file prefix) from each adapter's `periodic:` declarations; there is no hard-coded list. The bundled adapters declare `awkit tick`, `jobsctl run` (every pass also reconciles; the jobsctl adapter's entry reproduces `jobsctl cron install`'s line: absolute path, filtered `PATH`, the XDG variables, no env-file prefix, `run --quiet`), `review-watch poll`, `pr-watch poll`, `ticket-work sync`, `ticket-queue refresh`, `review-respond check`, `agent-spawn reconcile` (which runs `claude-session reconcile` first), `memoctl prune` and `notice-route flush`, plus opt-in `ticket-work start --auto` and `agent-spawn prune`. Tools that need periodic runs also provide their own `cron install|uninstall` for standalone use; both write the same tagged crontab block per tool (`# <tool> managed`), so one replaces the other.
- **Reboot recovery:** `jobsctl reconcile`, then `agent-spawn reconcile` (which runs `claude-session reconcile`); the workflows then resume through their normal polls.
- `awkit doctor`: checks that registered tools are installed and respond, adapters load, crontab is present, required env vars are set, required binaries resolve in a non-interactive shell (with each kind's `PATH` override applied), and reports the effective kind profiles, including whether each kind's required sandbox is available (`claude-session kinds --json`).

## 8. Claude session model (claude-session)

This section holds the cross-tool contract of claude-session: identifiers, kinds and the kind profile fields, the existence and meaning of states, outcomes and exit codes, the reporting and artifact contract, taint, the isolation guarantees and the hook names. claude-session's `docs/interface.md` is the single normative source for the detailed rules (launch order, flags, carry-over, the full state transition table, the outcome mapping, output by exit code and the generated isolation rules); this section links to its sections instead of restating them. Internal details (state store, modules, generated settings, transcript rendering) are in claude-session's `docs/design.md`.

### 8.1 Identifiers and kinds

**Identifiers.** Three ids exist:

| Id | Owner | Notes |
|---|---|---|
| `agent_id` | agent-spawn | One per agent; maps to a `csession_id`. |
| `csession_id` | claude-session | `cs-` followed by 8 lowercase base32 characters, allocated by `start` (or by `exec` when called without `--session-id`); exported to the session as `CSESSION_ID`. Commands accept any unique prefix of at least 4 characters after `cs-` (the `cs-` itself is optional in input; a shorter prefix exits 2, an ambiguous one 21; forgotten sessions never match). Ids are never reused, even after deletion. |
| `claude_session_id` | Claude Code | Claude Code's own UUID, captured from the SessionStart hook payload in both modes and updated on every SessionStart (it changes on `/clear` and on fork); resume always uses the latest. |

**Placing a session.** `start --json` allocates a `csession_id`, creates the session with run 1 as a **pending run** (a run no wrapper has adopted yet, with an adoption deadline `expires_at`), stores every per-invocation flag and freezes the fully resolved launch specification, so launch-phase problems exit 12 before anything is placed. It prints the session id, its directory, `expires_at`, `required_env_names` (the variable names the adopting process must have) and `argv`, the command line to place: `[<absolute path of claude-session>, "exec", "--session-id", <id>]`. `exec --session-id <id>` **adopts** the pending run with one compare-and-set and launches exactly the stored specification. `start --resume <id> [--fork]` does the same for a resume. A pending run not adopted before `expires_at` ends `not-started` (end reason `never_adopted`). The launch steps, which flags `start` and the adopting `exec` accept, and the refusals are specified in claude-session `docs/interface.md`, sections Launch order and Flags at start and adoption.

**Labels.** A label key matches `^[a-z0-9][a-z0-9_.-]{0,63}$`; a value is 0 to 256 characters from `[A-Za-z0-9._:/#@+=,-]` (no spaces or control characters), split at the first `=`. Every entry point (`--label`, `label add`, `label remove`, `list --label`, hook `labels` selectors) enforces this and exits 2 otherwise.

**Environment.** `exec` clears any inherited `CSESSION_*` variables, then exports `CSESSION_ID`, `CSESSION_KIND` (the run kind; a claimed value for consumers such as memoctl, not a verified identity) and `CSESSION_DIR` (the session's agent-visible directory, section 8.3), and prepends its own installation directory to `PATH` so `claude-session report` usually resolves (a user's shell profile may reorder `PATH`, so the standard instructions also name the absolute path). For isolated runs it drops relative and empty `PATH` entries and refuses a `PATH` entry inside a session-writable path (section 13.1). Hooks configured on claude-session itself get all inherited `CSESSION_*` cleared and receive the same id as `CSESSION_ID` (the design guide's `<TOOL>_ID` convention), plus `CSESSION_HOOK` and `CSESSION_OBJECT_TYPE`. These names are reserved: they are never config keys and the config environment loader ignores them.

**Kinds.** `--kind <name>` is a first-class flag on `exec`/`start`/`resume` (and on `agent-spawn launch/resume`), separate from labels; the launch kind is copied into a `kind=` label for display and filtering only. Without `--kind`, a new session uses the config key `default_kind` (built-in default `implement`, so a human running `claude-session exec` gets an ordinary trusted session) and a resume uses the previous run's kind; automation always passes `--kind`. A **kind profile** in claude-session's config holds:

| Field | Meaning |
|---|---|
| `permission_profile` | name of a permission profile (section 13.1) |
| `sandbox` | `required`, `preferred` or `off` (section 13.1) |
| `reads_third_party` | `true` makes the kind a third-party-reading kind (section 13); cannot be overridden per repo |
| `setting_sources` | which Claude Code setting sources load (`user`, `project`, `local`); `[]` loads none (no user or project settings, CLAUDE.md files, skills, installed plugins or hooks) |
| `mcp` | `inherit`, or `none` (`--strict-mcp-config` with no servers) |
| `cwd` | `session-dir` (the session's `$CSESSION_DIR/work/`) or `caller` |
| `env` | `inherit`, `allow`, `set`, `path_prepend` (section 13.1) |
| `read_dirs`, `write_dirs` | extra directories a sandboxed session may read or write (toolchains, caches) |
| `timeout`, `interactive_timeout`, `max_turns` | bounds (section 8.2): headless timeout, interactive wall-clock timeout, headless turn limit |
| `auto_exit`, `backstop` | auto-exit after `report done`; the headless Stop backstop |
| `implicit_done` | whether a clean headless exit without a report counts as implicit done (`false`: `exited-unreported`, end reason `no_report`) |
| `notes_context` | inject memoctl notes at session start (section 16) |
| `model` | model passed to `claude` (`null`: Claude Code's default) |
| `claude_args` | extra `claude` arguments; user config only, never accepted per call; isolated runs accept only an allowlist (`--verbose`, `--debug`) |

Built-in kinds (all with `auto_exit: true`, `backstop: true`, `max_turns: null`, `model: null`, `interactive_timeout: null`; `implicit_done: true` except where the table says otherwise):

| Kind | `reads_third_party` | `sandbox` | `setting_sources` | `mcp` | Default `cwd` | env inherit | Headless timeout | `notes_context` | `implicit_done` | Profile | Used by |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `implement` | false | off | all | inherit | caller | yes | 60 min | yes | true | `default` | ticket-work |
| `draft-ticket` | false | off | all | inherit | caller | yes | 60 min | yes | true | `default` | ticket-create |
| `audit`, `improve` | false | off | all | inherit | caller | yes | 60 min | no | true | `default` | session-audit, self-improve (post-v1) |
| `rank` | false | preferred | `[]` | none | `session-dir` | no | 15 min | no | false | `readonly` | ticket-queue |
| `review` | true | required | `[]` | none | `session-dir` | no | 120 min | no | true | `review` | review-run |
| `gate-check` | true | required | `[]` | none | `session-dir` | no | 15 min | no | false | `review` | gatectl |
| `respond` | true | required | `[]` | none | `caller` (a git checkout is required; review-respond passes its disposable checkout) | no | 60 min | no | true | `respond` | review-respond |

A **third-party-reading kind** is one with `reads_third_party: true`; section 13 applies stricter rules to it. An unknown kind name gets the full review profile (the most conservative built-in), is recorded under the given name (in `CSESSION_KIND` and the `kind=` label), and produces a warning; user-defined kinds in config start from the built-in review kind's fields. Kind names match `^[a-z0-9][a-z0-9_-]{0,63}$`. Callers may override profile settings per call, flags taking precedence over config (`--permission-profile`, `--sandbox`, `--setting-sources`, `--reads-third-party`, `--env-allow`, `--env-allowlist-only`, `--auto-exit`/`--no-auto-exit`, `--cwd`, `--timeout`, `--max-turns`, `--model`, `--input-file`, and on resume `--reset <setting>`); claude-session `docs/interface.md`, section Launch flags, gives their exact rules. Two of them matter across tools: `--reads-third-party` can only force the kind to true (never false) and, unless given explicitly in the same call, implies `--sandbox required`, no setting sources, `mcp: none` and no env inheritance; and `--env-allow` can never unlock a `secret_env` variable. Skill-wrapper tools pass a permission profile **file** from their bundled resources, `--sandbox required`, `--setting-sources ""` and `--env-allowlist-only` on every call (design guide section 11), so their safety never depends on another tool's config. `claude-session kinds --json` lists the effective profiles, including sandbox availability, the resolved `claude` binary and version, and the effective read and write directories. Because behavior keys off the explicit `--kind` argument, not the caller's identity, this respects section 3.4.

### 8.2 The session wrapper (`exec`)

`claude-session exec` is the **session wrapper**: it starts `claude` as a child process, waits, records the outcome, and exits with the outcome code (section 8.3). It runs in the foreground of whatever terminal or process hosts it. Under agent-spawn, it is itself run by `agent-spawn supervise` (section 9.2). `resume` is `exec` for an existing session (section 8.5). `wait <csession_id> [--run <n>] [--timeout <duration>] [--outcome-file <path>]` blocks until the session (or the given run) is no longer live and exits with its outcome code (exit 22 if its own timeout expires first). `--outcome-file <path>` asks for the outcome object to be written there atomically, exactly once, by whichever process finalizes the run. `--dry-run` prints the generated settings, `claude` argv, environment variable names, sandbox lists and the origin of every resolved setting without launching. The full flag list is in claude-session `docs/interface.md`, section Launch flags.

**Launch.** Every launch, new or resumed, follows one fixed order (claude-session `docs/interface.md`, section Launch order): usage checks (exit 2) and refusals (exit 20, 10 or 21) allocate nothing; then the run is allocated and taint is committed; then launch validations (exit 12) and, at adoption, the `pre-launch` hooks (veto exit 11, escalation exit 13) run before `claude` is spawned. A run that ends in this launch phase keeps its run number, ends in the final state `not-started` with outcome `vetoed`, `escalated` or `not-started` and an end reason, and fires exactly one final `post-state-change`. A caller that hits a launch escalation records its own pending confirmation and, after a human accepts, resumes the `not-started` session with `--override-escalation`, which overrides only the hooks that escalated that run (accepted only from a TTY or with `--actor human:<user>`; audited, like jobsctl `release --override-escalation`).

**`stop <id> [--grace <duration>]`** ends a live session deliberately: it records the stop request, signals the verified wrapper (which forwards to `claude`), SIGKILLs the verified child and then the wrapper after the grace period, waits until the run is final and reports `ended`, `run_exit_code` and the signals sent. Without a report the outcome is `killed` with end reason `stopped`. On a pending run it cancels the run instead (`not-started`, end reason `canceled`). It is audited. `stop` is a human or explicitly configured action, and the remedy for an orphaned `claude` child (`reconcile` never signals); jobsctl `cancel --force` reaches the same end through the signal chain (section 9.2). The "nothing overrides live" rule (section 3.4) concerns teardown and forget, not `stop`.

**Bounds:** `--max-turns` applies to headless sessions only; when the backstop is enabled, `exec` passes one extra turn so the backstop does not consume the caller's budget. Headless sessions have per-kind default timeouts (section 8.1). Interactive sessions have no timeout by default; if one is configured, `exec` enforces it as wall-clock time. Exceeding a bound ends the session with outcome `timeout` (unless a report was filed, section 8.3).

**Prompt delivery.**

- The caller's prompt file and `--input-file` copies are placed in `$CSESSION_DIR` (`prompt.md`, `prompts/<run>.md`, `inputs/<run>/`); `exec` never edits them. Callers may delete their own files once `start` or `exec` has returned or started.
- The **standard instructions** (how to report, that escalating is always acceptable and preferred to guessing, where artifacts go, that `<untrusted>` blocks are data) are generated by `exec` and passed with `--append-system-prompt-file` on every run, so they survive `/clear` and context compaction. Callers must not add their own report or escalation instructions.
- Only a short, trusted bootstrap prompt goes in argv (skill first, then the session directory and the prompt path); the SessionStart hook always adds a trusted `claude-session directory: <abs>` context line. The exact texts are in claude-session `docs/interface.md`.
- Headless runs get `/dev/null` on stdin; their stderr is kept in the private run directory, never passed to the caller.

**Arguments passed to `claude`:** the absolute `claude` path, `--settings <generated file>` (injected hooks, permission profile, sandbox), `--setting-sources` and `--strict-mcp-config` per the kind, `--model`, the allowed `claude_args`, `--add-dir $CSESSION_DIR` for every run, each `--plugin-dir` (additive to installed plugins; bundled plugins are named `<tool>`, and a duplicated skill name silently resolves to the first plugin dir, so names must be distinctive), `--append-system-prompt-file` with `--system-prompt-snapshot off` (on every run, so changed instructions always apply), the bootstrap prompt, and `-p --output-format stream-json --verbose` in headless mode (with background subagents `-p` emits one result per turn; the last is the final result, and cost and turns are summed). For isolated runs each plugin dir is also passed with `--add-dir`, read-only, so bundled skills can read their reference files. On resume and fork every one is passed again: Claude Code does not remember them across `--resume`. Every run, of every kind, also gets the generated report permissions, so `report` works in every kind and mode.

**Injected hooks.** Each runs `<absolute interpreter> -I -m claude_session hook-event --state-dir <absolute state dir> <event>` for `SessionStart`, `UserPromptSubmit`, `PermissionRequest`, `Notification` (permission prompt, idle prompt, elicitation dialog), `PostToolUse`, `Stop` and `SessionEnd`, each with an explicit timeout (Claude Code silently drops a timed-out hook's output); `PreToolUse` is not injected. `hook-event` records the transition in `state.db` in one short transaction and exits 0 with no output, except for the headless Stop backstop (block once per run when no report was filed), report rejections and the SessionStart context. It reads its per-run configuration only from the session's private directory, never from a file the agent can write. On an internal error it logs and exits 0; `exec` re-derives the final state when `claude` exits. The transition each event causes is in claude-session `docs/interface.md`, section State transitions.

**Lifecycle hooks.** `exec` fires the tool's own lifecycle hooks: `pre-launch` (above) and `post-state-change`, fired on every real state change (including activity changes, so notification wiring should filter on `state`), also when `reconcile` or another command changes a run whose wrapper is gone. Delivery is at-least-once and in order; each payload carries an `event_id` for deduplication, the run kind, `reads_third_party`, `sandbox_active`, the state and previous state, and the report fields when present (summary and reason marked untrusted). Hook entries may carry selectors (`kinds`, `exclude_kinds`, `labels`, and for `post-state-change` `states`); recursion is prevented only by selectors, e.g. a gatectl `pre-launch` hook excludes the `gate-check` kind. A `decision_id` printed by a `pre-launch` hook is recorded on the run and in the launch log event (design guide section 8).

**Auto-exit.** After `report done`, at the next Stop with no background tasks, `exec` waits a short delay, re-checks that nothing newer happened, and then ends the session by sending SIGTERM to the exact `claude` child PID it started (never by pattern), followed by SIGKILL to the same verified PID after a grace period if needed. This closes an interactive window. The session is recorded as `exited`, with its outcome taken from the report. Configurable per kind (and per call), default on. Timeouts end the child the same way.

**Signals.** Interactive `claude` stays in the terminal's foreground process group, and `exec` ignores SIGINT (Ctrl-C never counts as a kill); headless `claude` runs in its own process group. `exec` forwards SIGHUP and SIGTERM (and headless SIGINT) to the exact child PID and records its intended cause on the run before sending any signal; on Linux a headless child also gets a parent-death signal, so it never outlives its wrapper. The signal table (signal, mode and phase) and how each cause maps to an outcome and end reason are in claude-session `docs/interface.md`. A filed report wins over `killed` (section 8.3). Signals go only to exact verified PIDs, plus the process groups of hooks claude-session spawned; processes the agent started itself (e.g. a dev server) are not signaled.

**Liveness.** Liveness checks use PID plus process start time, so PID reuse is safe, and check both the wrapper and the recorded `claude` child. `status`, `list`, `wait`, `resume`, `start --resume`, `stop` and `forget` run the single-session check inline, so no cron job is needed for correctness; `reconcile` does the same for all sessions. They finalize a run only when its wrapper is dead; finalization is a compare-and-set, so a run gets exactly one final event and one final `post-state-change`, and events a dead wrapper did not deliver are delivered late, never lost.

### 8.3 Reporting and outcomes

**Session directories.** Each session has two directories under claude-session's state root (`~/.local/state/claude-session/`, XDG-aware):

- `$CSESSION_DIR` = `sessions/<csession_id>/`, visible to the agent: `prompt.md`, `prompts/<n>.md`, the standard-instructions file, `run.json` (the run's `csession_id`, run number, the state root, report limits, directory identities and input names, which `report` reads), `inputs/<run>/` (each run's `--input-file` copies, kept for later runs), the session `secret`, `outbox/`, `artifacts/`, `work/` (the cwd for `cwd: session-dir`), and the empty `gh-empty/` and `empty-gitconfig`. The agent may write only `outbox/`, `artifacts/` and the cwd (`work/` when it is the cwd).
- `private/<csession_id>/`, never visible or writable to an isolated session: per-run records (generated settings, hook configuration, the headless result and stderr, staged prompt and input copies, the permission-profile snapshot, the keyed index used by the `contains_secret` check, and frozen artifacts).

Sandboxed kinds also get a private, short temporary directory (`/tmp/csession-<uid>/<csession_id>/`), exported as `TMPDIR` and removed at the end of every run. Session directories are kept while the session is not forgotten (they back parked agents) and deleted a retention period after `forget`.

**Session secret.** `exec` writes a random secret (32 bytes, hex) to `$CSESSION_DIR/secret` with mode 0600 at the start of every run (rotated on each run, including resumes); `state.db` stores only its SHA-256, compared in constant time. The session can read it; sandboxed sessions cannot write it, and cannot read any other session's directory (section 13.1).

**`report`.** The session reports its status explicitly: `claude-session report done|blocked|failed|needs-input (--summary-file <path>|- | --summary "...") [--reason-file <path>|-] [--artifact <path>]`. `done` requires a summary; `blocked`, `failed` and `needs-input` require a reason. Summaries and reasons are untrusted (schemas mark them) and size-capped. Under `dontAsk` only the plain command forms the standard instructions list are allowed (a summary file written with the Write tool, `--summary`, or a heredoc on stdin; never `$(…)` or `cd … &&`). `--artifact` names one regular file directly inside `$CSESSION_DIR/artifacts/` (a bare name or that path; symlinks and hard-linked files are rejected, never resolved) that fits a size cap.

- `report` runs inside the session (inside the sandbox for sandboxed kinds) and never opens `state.db`. It validates its arguments locally (exit 2 on any problem), writes the request, authenticated with the session secret, atomically to `$CSESSION_DIR/outbox/`, prints that the report is queued, and exits 0.
- The request is **ingested** by the next injected hook that runs outside the sandbox (`PostToolUse`, `Stop`) or by `exec` after `claude` exits. Ingestion re-applies every check, checks the secret and that the request belongs to the current, live run, and **freezes** the artifact by copying it to the private directory with its SHA-256 and size. Requests are claimed by an atomic rename, so none is ingested twice. A summary, reason or artifact (scanned as a private copy) containing the value of a passed `claude_auth_env` variable, a `secret_env` variable present in `exec`'s environment, or the run secret is rejected (`contains_secret`); claude-session stores only a keyed index of those values, never the values. A rejected request is reported back to the agent through the `PostToolUse` hook, so it can fix and file the report again.
- Callers read the frozen artifact path from `status --json`; the working copy in `artifacts/` is scratch. The run's artifact is the latest report's artifact, or none if the latest report attached none; the standard instructions tell the agent to attach the artifact again on every report.
- `report needs-input --reason-file ...` is the **escalation** path ("I need the user's judgment on X"). It sets state `needs-input(escalation)`.
- Self-labeling (`agent-spawn label add --session`, section 9.1) uses the same secret, checked through `claude-session verify-secret <id>` (secret on stdin; exit 0 match, 11 otherwise).

**Reports are per run.** A resume starts a new run and clears the current report. Within a run, the most recent report determines the outcome, and a filed report is sticky: later Stop or idle events do not clear it.

**Precedence.** A filed report wins over `killed`, `timeout` and `lost`: the outcome is the report's code, while the end reason still records why the run ended (for example `stopped`, `timeout` or `wrapper_lost`). For headless runs, a clean exit without a report is implicit done when the kind has `implicit_done: true` (the `-p` result is frozen as artifact `result.md`, QRT-11); callers that need an explicit verdict check `report.implicit`. The complete mapping from causes, reports and exit status to outcomes and end reasons, interactive and headless, is in claude-session `docs/interface.md`, section Outcome mapping.

Callers read results via `claude-session status <id> --json` (state, final report: status, summary, artifact, reason; headless cost), `claude-session wait <id> --json`, or `agent-spawn show <agent_id> --json`, never via the session's stdout.

**Outcome codes.** `exec`, `resume`, `wait`, `agent-spawn launch/resume --wait`, and any tool that waits on a session and passes its outcome through, exit with:

| Exit | Outcome |
|---|---|
| 0 | reported done (including implicit done) |
| 11 | a pre-launch hook vetoed the launch (phase launch; the session never started) |
| 12 | the run was never started (launch phase failed; state `not-started`) |
| 13 | the run's report is blocked or needs-input (escalation), or a `pre-launch` hook escalated; for agent-spawn (when not promoted), the agent is parked with `needs_attention: escalated` or `blocked`, and its job, if any, becomes held (section 9.3) |
| 14 | exited-unreported |
| 15 | killed |
| 16 | timeout |
| 17 | lost |
| 18 | reported failed |

With `--json`, waiting commands also print the outcome object (`phase: launch|session`, `outcome`, `end_reason`, ...); callers branch on the JSON when they need precision. What each exit code prints is in claude-session `docs/interface.md`, section Output by exit code; `end_reason` is a closed enumeration listed there.

### 8.4 States

A session is **live** in `starting`, `working`, `idle`, `needs-input` and `reported`; the other states (including `not-started`) are final until a resume. The complete transition table, `(state, activity, event) → (state, activity, needs_input_reason)`, is in claude-session `docs/interface.md`, section State transitions.

| State | Meaning |
|---|---|
| `starting` | allocated or being launched (a pending run, or `claude` not yet past SessionStart; an interactive session in a never-trusted cwd stays here while Claude Code's trust dialog waits) |
| `working` | the agent is working (a prompt was submitted, a tool ran, background tasks run, or a headless run is under way) |
| `idle` | the agent finished its turn and waits for input |
| `needs-input(permission)` | a permission prompt is waiting; a denied prompt stays here until the next prompt |
| `needs-input(escalation)` | the run's report is an escalation (`report needs-input`) the user has not answered yet; sticky until the next prompt |
| `needs-input(question)` | the agent asked the user a question (AskUserQuestion) |
| `needs-input(elicitation)` | an elicitation dialog is waiting |
| `reported(done\|blocked\|failed\|needs-input)` | the run has a report (or implicit done, or an answered escalation); keeps an activity (`working` or `idle`) |
| `exited` | `claude` exited after a report or an escalation was filed in this run, whatever the end reason |
| `exited-unreported` | `claude` exited with no report in this run |
| `killed` | no report in this run, and the run was ended by a signal: `stop`, a signal forwarded by the wrapper (e.g. the hosting terminal closed, or a job was canceled with `--force`), or a signal the wrapper did not send |
| `timeout` | no report in this run, and a timeout or `--max-turns` was exceeded |
| `lost` | the wrapper and the `claude` child are gone with no final record and no report in the run |
| `not-started` | the run ended in the launch phase (veto, escalation, failed launch validation, interrupted launch), a pending run was never adopted, or `stop` canceled a pending run; a resume launches again (with a fresh conversation if no Claude session id was captured) |

**Display priority.** While the run waits for the user, `state` is `needs-input` with `needs_input_reason` `permission`, `question`, `elicitation` or `escalation`, whether or not a report exists; the report stays in `report.status`. The activity (`working`, `idle`) is tracked in every live state, including `needs-input`. So callers watching `state` alone never miss a session that waits for them. Notifications match `state == needs-input` together with `needs_input_reason`.

If the wrapper dies while the `claude` child lives on, the session stays live (hooks keep recording it, `status` shows the wrapper gone, and resume is refused as `live`) until `stop` ends the child or `reconcile` finds both gone.

State changes fire the tool's own hooks (`post-state-change`). Standalone, claude-session only records the final state and exits with the outcome code. Policies applied around the session (window status prefix, auto-resume, promotion to interactive, parking) are owned by agent-spawn (section 9.3). `parked` is not a session state: it is an agent-spawn agent status (section 9.1).

### 8.5 Resume and forget

`resume <csession_id>` is `exec` for an existing session: it takes the same launch flags, plus `--fork` and `--allow-tainted` (below), and exits with the same outcome codes. It runs `claude --resume <claude_session_id>` (the latest captured id) with every argument of section 8.2 passed again and an optional new prompt file, and moves a final session to `starting`. A session with no captured `claude_session_id` (it never reached SessionStart, e.g. quit at the trust dialog or failed at launch) is resumed as a fresh conversation, with a warning; the prompt and inputs of a run that ended `not-started` carry over, because they were never delivered. A resume whose launch fails ends `not-started`.

- **What carries over.** Each run stores its launch settings, resolved and marked by origin; a resume resolves built-in kind → config kind → per-repo override → the previous run's explicit flags → the flags given now, so a config change takes effect on the next resume unless a flag set that value. `--kind` omitted on resume means the previous run's kind; a `--kind` given applies to that run only, and the session's launch kind and `kind=` label never change. A kind change carries only repo, cwd and mode; a mode change drops the stored bounds; `--reset <setting>` returns a setting to the kind's profile; per-invocation flags (prompt, skill, hooks, outcome file, inputs, overrides) are never carried. The complete table is in claude-session `docs/interface.md`, section Resume and fork carry-over. `--dry-run --json` shows the origin of every resolved setting.
- **cwd.** A resume or fork always runs in the previous run's resolved cwd (Claude Code keys transcripts by project directory); `--cwd` is accepted only if it resolves to the same path (else exit 2).
- **Refusals,** checked atomically with the move to `starting`: a live session, or one whose `claude` child is still alive, is refused with exit 20 (`reason: live`) (Claude Code itself would let two processes resume one session and interleave their writes); a tainted session (below) with exit 20 (`reason: tainted`); a launch failure (e.g. the sandbox is unavailable) exits 12. (agent-spawn's `resume` accepts an `agent_id` or labels instead; section 9.4.)

**Fork.** `resume --fork` runs `claude --resume <claude_session_id> --fork-session --session-id <new uuid>`: the fork is a new session with its own `csession_id` (recording `forked_from`) whose first run carries over the source's latest run (without `--kind` its run kind is the source's last run kind) and runs in `--cwd` when given (any path that passes the path rules) or else the source's resolved cwd; a plain resume always runs in the previous run's cwd. Labels are not copied: the fork gets `kind=<its run kind>` plus the `--label` values given. Taint is copied, so forking a tainted source into a kind that is not third-party-reading needs `--allow-tainted`. The original session's record and conversation are unchanged; forking a live session is allowed. review-respond uses forks so the original implement session never receives untrusted comment text (section 5.3).

**Taint.** A session is marked `tainted` once any run of a third-party-reading kind is allocated on it (including a fork's first run and a fresh session launched with such a kind); the mark is committed at allocation, before any process starts, and a fork inherits taint from its original. Taint is never cleared and is shown in `status`/`list --json`. `resume` of a tainted session with a run kind that is not third-party-reading is refused (exit 20, `reason: tainted`) unless `--allow-tainted` is passed, which only a human gives explicitly: claude-session accepts it only when stdin is a TTY or `--actor human:<user>` is given (the dashboard's path after its own confirmation), and records it in its audit log. Automation never passes it.

`forget <csession_id>` hides the session record (later commands report it as not found, exit 10) and records the action in the audit log; it refuses live sessions (exit 20, `reason: live`), including a pending new-session record (cancel it with `stop` first). A bulk mode (`forget --older-than <duration>` with state, kind and label filters) skips live sessions and pending records; tools that run headless sessions only for their results forget them after collecting the results. `reconcile` deletes the record and both session directories (including frozen artifacts) a retention period after `forget` (default 30 days); the id is never reused; callers copy any artifact they keep long-term (review-run stores its own copy). Claude Code's own transcripts follow Claude Code's cleanup setting.

### 8.6 Spike results

The spike that opened the claude-session design session ran against Claude Code 2.1.312 on Linux and confirmed the behavior this section relies on: `--plugin-dir` is additive; `--settings` hooks and permissions merge with other sources; `--resume` keeps the Claude session id but does not remember flags; `--session-id` can pre-assign a new session's or a fork's id; the Stop block works headless; the `-p` JSON carries `session_id`, `result`, `is_error` and `total_cost_usd`; SessionStart reports its source; hooks inherit the `claude` process's environment; `--setting-sources ""` loads no user or project settings, CLAUDE.md, skills or installed plugins while `--settings` and `--plugin-dir` still apply; `--strict-mcp-config` leaves no MCP servers; fork leaves the original unchanged and resumable; SIGTERM to the exact child ends a session cleanly and resumably. It also found that permission rules are not a security boundary (deny rules were evaded through `sh -c`, `git -C` and interpreters, and the user's tmux server and SSH agent were reachable), which is why section 13.1 relies on Claude Code's sandbox. claude-session checks at launch that Claude Code is at least the verified version (configurable). Three live verification runs (headless, interactive, sandbox) then settled most open questions, among them: `-p` waits for background subagents and emits one result per turn; with no setting sources Claude Code starts in `auto` mode unless a mode is set; only `Edit(...)` allow rules permit the Write tool; AskUserQuestion appears as a permission request; the sandbox opens a linked worktree's common git dir partly writable and ignores single-`*` globs. The details, and the behaviors still to verify, are recorded in claude-session's `docs/design.md`, and a `live` test suite in that repo re-checks every relied-on behavior against new Claude Code versions.

## 9. Agent lifecycle (agent-spawn)

### 9.1 Agents and windows

- **Agent ≠ window.** An agent is a Claude session launched by agent-spawn, identified by its `agent_id` and labels. It persists in agent-spawn state until its owning workflow (recorded as label `owner=<tool>`) says the work is finished. Windows are disposable.
- **Agent statuses:** *live* (a supervised session for the agent is live), *parked* (no live session; resumable; this includes finished headless agents), *torn down* (worktree removed, session forgotten; kept as a tombstone for N days). Selectors (`--label`) exclude tombstones; `resume` of a torn-down agent exits 10.
- **Labels:** agent-spawn is the authoritative label store for agents. It passes the agent's labels to `exec --label` and mirrors later label changes onto the session. It reads the job id from the env var named by config `job_id_env` (default `JOBSCTL_JOB_ID`) and records it as label `job=<id>`. `label add/remove <agent_id>` edits labels.
- **Self-labeling:** `label add --session <id> key=value` lets an agent label itself (e.g. `agent-spawn label add --session $CSESSION_ID pr=github.com/org/repo#42`). It is allowed only when `<id>` equals the caller's `CSESSION_ID`, the caller presents that session's secret (read from its 0600 file in `$CSESSION_DIR` and verified with `claude-session verify-secret`, section 8.3), and only for allowlisted keys (default `pr`). The secret proves access to the session's directory, not just a caller-controlled env var. Third-party-reading kinds cannot read `state.db` or any other session's secret (their sandbox denies reads of claude-session's whole state root except their own session directory), and their permission profile also denies `agent-spawn` (section 13.1).
- **Attention:** agent-spawn never creates attention items and never notifies directly. It records `needs_attention: <reason>` on the agent, where the reason is `unreported`, `escalated`, `blocked`, `failed` or `lost` (listed by `list --needs-attention`), and fires hooks: `post-escalate`, `post-park` (with a reason, e.g. `unreported`) and `post-state-change` (payload includes `agent_id`, `csession_id`, labels, state and reason). `needs_attention` is cleared by a successful resume, by teardown, or by `ack <agent_id>`. `post-state-change` is the recommended source for agent notifications and the harness.

### 9.2 Launch, hosting, waiting and jobs

- **Repo-config baseline:** when an agent gets a worktree, the baseline of section 13.2 rule 10 is recorded by wtctl: `wtctl create --holder <agent_id>` records it for `--worktree new` (after bootstrap), and `launch` runs `wtctl adopt <path> --holder <agent_id>` for `--worktree <path>`. agent-spawn stores the wtctl record id and keeps no hashes itself.
- **Launch flags:** `--kind`, `--skill`, `--plugin-dir` (repeatable, passed through), `--prompt-file` (and `--prompt` for trusted text only), `--repo <repo-id>`, `--branch <name>`, `--ref <sha>`, `--worktree new|<path>|none`, `--cwd <path>|session-dir`, `--mode interactive|headless`, `--placement window|here`, `--ephemeral` (tear down after the run), `--wait`, `--label`, plus the per-call profile overrides of section 8.1 (passed through to `exec`). Defaults: `--mode interactive`, `--placement window`, `--worktree none`. The local clone for `--repo` is resolved with `wtctl locate`.
- **Placement:** an optional worktree via wtctl; a window via termctl (`--placement window`) or the current terminal (`--placement here`, e.g. `ticket-create draft`). `--placement window` requires tmux: without it, an interactive launch fails with exit 12 and a hint (use `--placement here` or `--mode headless`). Headless launches need no tmux, which is why shareable tools use headless mode.
- **Process hosting:**
  - Interactive, `--placement window`: the tmux window runs `agent-spawn supervise <agent_id>`, which runs `claude-session exec`. Because a tmux window inherits the tmux server's environment rather than the caller's, agent-spawn writes an env file in its state dir (`PATH`, the job id, allowed variables) that `supervise` loads. The env file has mode 0600 and contains only variables the kind allows, never variables listed in claude-session's `secret_env` or any `token_env`; `supervise` deletes it immediately after loading. Secret variables a kind allows reach `supervise` from the launching process's environment, never through the file (section 20).
  - Interactive, `--placement here`: `supervise` runs in the foreground of the current terminal; promotion and window status prefixes do not apply.
  - Headless without `--wait`: `supervise` is detached (double fork) and its PID recorded.
  - Headless with `--wait`: `supervise` runs in the foreground.
  - When `exec` returns, `supervise` records the outcome, applies the post-exit policies (section 9.3), parks the agent, and exits (which closes an interactive window).
- **Signals:** in interactive mode `supervise` ignores SIGINT and ignores SIGHUP until its bookkeeping is done (SIGHUP reaches `exec`, which forwards it to `claude`). **Cancellation chain:** every layer forwards SIGTERM to its exact child PID: the jobsctl shim → the job command → `agent-spawn launch|resume --wait` (which signals the recorded `supervise` PID) → `supervise` → `exec` → `claude`.
- **`--wait`:** `launch` and `resume` block until the agent's session is no longer live and no promotion is pending (section 9.3), and exit with the outcome code (section 8.3). Without `--wait` they return once the agent is placed. In interactive window mode, `launch --wait` polls the agent's status.
- **Jobs:** exactly one layer submits to jobsctl: the workflow tool (L3) or a human. agent-spawn never uses jobsctl; a workflow calling it from inside a job never re-enqueues. Jobs always use `--wait`, so a job's lifetime covers the whole agent run including promotion, and the jobsctl cap keeps counting it (an interactive agent waiting for the user still occupies its slot). Resumes performed by workflows also go through jobsctl when it is available.

### 9.3 Supervision and post-exit policies

`supervise` applies these policies around `exec`:

- **Status prefix:** `supervise` polls `claude-session status` (no extra hook process) and sets the window's status marker with `termctl mark <id> attention` and clears it with `termctl unmark <id>` (termctl's config decides how a marker is displayed). The marker is set on `needs-input` and on `idle` (so a brainstorming agent waiting for you is visible), and cleared on `working`. On each state change the `post-state-change` hook fires; any notification comes from what that hook is wired to.
- **Done:** auto-exit is performed by `exec` (section 8.2); `supervise` records the outcome and parks the agent.
- **Unreported exits:**
  - Headless `exited-unreported` → automatically resumed headless once with "report your status"; if still unreported → escalated (`needs_attention: unreported`, `post-escalate`), and `--wait` exits 14.
  - Interactive `exited-unreported` → parked with `needs_attention: unreported` and `post-park` (reason `unreported`); no automatic resume. The dashboard offers a one-key "resume to report". (Interactive sessions only end when the user exits them, or by auto-exit after done.)
- **Reported failed** → parked with `needs_attention: failed`; `--wait` exits 18.
- **Killed** (the window closed, or the job was canceled with `--force`) with no report → parked; no automatic resume.
- **Promotion (headless → interactive):** a per-kind setting. When enabled and tmux is available, a headless session ending blocked or needs-input is promoted: its supervisor (which remains the only supervisor) runs `claude-session start --resume <csession_id> --mode interactive ...` with the same kind profile, opens a window via termctl running the printed `exec --session-id` argv, and waits with `claude-session wait <csession_id> --run <run>` on the run `start` returned; `--wait` keeps waiting until the promoted session is no longer live. An escalation answered in the promoted session keeps the run's report at needs-input until the agent files a new report. When promotion is disabled or unavailable, the agent is parked with `needs_attention: escalated` (or `blocked`), `post-escalate` fires, and `--wait` exits 13.
- **Held:** a job ends held (exit 13) only when the session ends blocked or needing a human and is not promoted: promotion is unavailable or disabled, or an interactive session exits after a blocked or needs-input report. Held agent jobs are never released; the submitting workflow resolves them (`jobsctl resolve`) when it sees the outcome, and the agent continues through `agent-spawn resume` (section 5.1, jobsctl).
- **Lost** sessions (found by `reconcile`) get `needs_attention: lost`. `reconcile` also parks agents whose supervisor died.

### 9.4 Resume, attach and acknowledge

`agent-spawn resume (<agent_id> | --label k=v) [--mode headless|interactive] [--kind <k>] [--fork] [--prompt-file F] [--wait] ...` takes the same flags as `claude-session resume` (passed through) and resumes the session under supervision in the agent's original cwd (worktree). Without `--kind` the resume uses the previous run's kind (claude-session's default). With `--fork`, the forked session (section 8.5) becomes a **new agent**, by default in the same cwd; `--cwd <path>` (passed through to claude-session) runs the fork in a different cwd, such as review-respond's disposable checkout. The fork is labeled only with the `--label` values given and records `forked_from=<agent_id>`; it gets no wtctl record of its own and never owns a worktree or checkout (review-respond removes its throwaway checkout itself), and `show` reports `repo_config_changed` only for agents with a wtctl worktree record; the original agent is unchanged. A refusal for taint (exit 20, `reason: tainted`) is passed through. The default mode is the agent's original mode; a window is opened only in interactive mode. A `--kind` given on resume applies to that run only and is not carried to later runs (section 8.5). If several agents match the selector it exits 21; if the agent's session is live it exits 20 (`reason: live`), and workflows retry on their next poll; a torn-down agent exits 10. Resuming an agent in a kind that is not third-party-reading after a third-party run on its worktree is refused (exit 20, `reason: repo_config_changed`) if `wtctl baseline check` reports a change, in either class, since the baseline was recorded or last accepted (section 13.2 rule 10); a human clears it with `wtctl baseline accept` after inspecting the change. To host a resume in a window, agent-spawn uses `claude-session start --resume <csession_id> [--fork]`, which runs the refusal checks synchronously, and places the printed `exec --session-id` argv.

`attach <agent_id>` focuses a live agent's window; on a parked agent it exits 10 with a hint to use `resume`.

`ack <agent_id>` clears the agent's `needs_attention` without resuming it.

### 9.5 Teardown and prune

- `teardown <agent_id> [--merged-head <sha>] [--force]` is triggered when the owning workflow declares the work complete (e.g. `ticket-work sync` sees the PR merged), by `--ephemeral` after the run, or manually.
- Teardown removes only worktrees agent-spawn created (`--worktree new`, created with `wtctl create --holder <agent_id>`; teardown runs `wtctl remove --holder <agent_id>`, which refuses with `reason: held` while another agent still holds the worktree) and forgets the session; for a `--worktree <path>` agent it runs `wtctl forget <record> --holder <agent_id>` instead, which drops the adopted record only when no other holder remains. Live sessions are **always** refused (exit 20, `reason: live`), even with `--force`, and so is removing a worktree in which any agent is live. Teardown is itself the decision to remove, so it passes `--yes` to `wtctl remove`, which checks the repo-config baseline's git-class items before running any git command in the worktree other than the hardened integrity read (exit 20, `reason: repo_config_changed`; changed Claude project config is only reported), refuses a worktree a process still uses (`reason: in_use`), and refuses a dirty or unpushed worktree (exit 20) unless a human passes `--force`, which teardown passes through; automation never does. Teardown passes wtctl's refusals through. Workflows pass the merged PR head (`--merged-head`) so squash merges do not block teardown, and retry refused teardowns on the next sync.
- Torn-down agents remain as tombstones for N days.
- `prune --older-than <age>` tears down long-parked agents. It has no default age (a no-op unless `--older-than` or config sets one) and skips agents matching config `prune.protect_labels` (label keys or `key=value` pairs; default `[owner]`) unless `--include-owned`. No label has built-in meaning; the protection comes from config.

### 9.6 Placement and nesting

- **Placement:** owned by termctl (section 5.1): agent-spawn passes the agent's labels (and optionally a placement name) and termctl's config decides. The end state is fully configurable (naming scheme, prefix, session choice, new vs existing session, windows vs panes, max panes per window, layout, status prefix such as a bell, rulesets per repo/epic/project/kind matched via labels). v1: one new shared session, a window per agent, window named after the work (e.g. `KEY-12`, `PR#42 review`), with the status prefix of section 9.3.
- **Nesting:** review skills may themselves spawn subagents; Claude Code limits subagent nesting depth, so agent-spawn always starts top-level `claude` processes, never via the Agent tool.

## 10. Key flows

### 10.1 Review request (flow A, priority slice)

0. When jobsctl is used, `jobsctl run` runs from cron (or as a loop).
1. Cron runs `review-watch poll`.
2. forgectl lists PRs that request your review directly; draft PRs, bot-authored PRs and PRs you already reviewed yourself are skipped.
3. For each new queue item (PR, head sha, review-request instance), review-watch enqueues a jobsctl job (queue `reviews`, `--unique-key review:<pr>@<sha>`) or, without jobsctl, spawns a detached process under its internal cap, running `review-run run <pr> --mode headless --label rw-item=<id>`.
4. review-run pre-fetches diff and metadata into a fenced prompt file. If `run_pr_code: true`, it first runs the throwaway-checkout sequence of section 13.2 rule 9 and appends the fenced command output to that file. It then calls `agent-spawn launch --mode headless --kind review --cwd session-dir --skill review-run:review-pr --plugin-dir <bundled> --worktree none --prompt-file <file> --permission-profile <bundled file> --sandbox required --setting-sources "" --env-allowlist-only <var> ... --label owner=review-run --wait` (section 13.1). The session never has a checkout.
5. The session reports done with the review artifact. review-run validates it against the review-draft schema, stores the run with its own copy of the artifact, and tears down the agent; review-watch copies the artifact into its review draft; its `post-draft` hook calls notice-route (Slack/Home Assistant).
6. You accept (CLI or TUI). If the head moved, the review draft is stale (`rerun`, or `accept --reanchor` to re-anchor onto the new head via pr-comment). Otherwise pr-comment posts one review (COMMENT, or REQUEST_CHANGES per the draft) with inline comments and an attribution footer, and records an audit entry.
7. Optional: gatectl decides auto-post / auto-approve, in shadow mode first, within the hard rules (section 5.3).
8. A new review starts only on a fresh review request or an explicit `rerun`, up to the configured per-PR round limit.
9. If the review session escalates, the run is `escalated`, its job is held and its agent is kept. Once the agent is resumed and the run is done or failed (or the item is rejected), `poll` resolves the held job.

### 10.2 Ticket work (flow B)

1. `ticket-work start` (or `start --auto` from cron, only while `jobsctl capacity` is above 0, counting unresolved pending starts) → `ticket-queue next --claim`, or `ticket-queue claim KEY` for an explicit key.
2. `pre-enqueue` hooks run (may veto, or escalate with exit 13, e.g. a gate).
3. From a TTY, ticket-work shows and confirms the assignment, sprint and transition (public default) and applies them with `ticketctl ... --yes`. Without a TTY it records a pending confirmation (`post-pending`) and stops (section 12.4); `confirm <id>` applies them and continues.
4. It enqueues a jobsctl job (queue `tickets`, `--unique-key ticket:<KEY>`) running its internal, resume-aware job command.
5. The job runs `agent-spawn launch --kind implement --mode interactive --repo <repo-id> --branch <branch> --worktree new --skill ticket-work:implement-ticket --plugin-dir <bundled> --permission-profile <bundled file> --env-allowlist-only <vars> --label ticket=KEY --label owner=ticket-work --wait`: wtctl resolves the clone and creates the worktree, termctl opens window `KEY` in the shared session, claude-session starts Claude with notes context. If the launch fails, ticket-work restores the previous status, releases the claim with `--failed`, and fires `post-start-failed`.
6. The agent brainstorms with you, implements (including in-repo doc updates), pushes, opens a draft PR (the implement skill enforces the draft default), may record `pr=...` via `agent-spawn label add --session $CSESSION_ID`, and reports done. `exec` auto-exits the session, `supervise` parks the agent and exits, the window closes and the job ends.
7. `ticket-work sync` (cron, or early via the harness on pr-watch changes) is the guaranteed linking path: it renews the claim, links the PR, adds the `pr=` label, adds a pr-watch watch, writes an audit entry, checks the PR's current state via forgectl, and applies the status map: `pr_opened` → testing status; `pr_merged` → done (with resolution), then `agent-spawn teardown --merged-head <sha>` and release of the claim.

### 10.3 Review response (flow C)

1. pr-watch detects a new comment, review comment or review on your PR (through the query watch owned by review-respond).
2. A harness rule (or cron running `review-respond check`) runs `review-respond respond <pr>`. Only comments from collaborators with write access or configured reviewers trigger it; your own comments, comments carrying the awkit marker and configured bot comments are ignored; the round cap applies.
3. It finds the agent with `agent-spawn list --label pr=... --json` (preferring its own respond fork, then `prefer_owner`, else the most recent) and checks that neither the agent nor its respond fork is live. It enqueues one job per PR (queue `respond`, `--unique-key respond:<pr>`; without jobsctl it runs the job command directly) whose job command creates a throwaway checkout at the PR head (`wtctl create --throwaway --ref <sha>`) and runs `agent-spawn resume <agent_id> --cwd <throwaway> --kind respond --prompt-file <fenced "new review comments" file> --permission-profile <bundled file> --sandbox required --setting-sources "" --env-allowlist-only <var> ... --wait`, with `--fork --label pr=<pr> --label owner=review-respond` on every round: the first round forks the original agent, so the comments go to a fork and never to the original implement session, and each later round forks the previous respond fork into the new throwaway (a plain resume would keep the previous round's cwd; section 5.3). The prompt file holds only comments from eligible authors. The session runs in the original agent's mode, in the throwaway checkout, and the comments count as delivered once it reaches `working`. If no agent exists and the PR is opted in (and not from a fork), it launches a fresh respond-to-review session in the throwaway checkout with `--label owner=review-respond`.
4. The agent edits files in the throwaway checkout (it can neither commit nor push) and reports replies, the changed files and a proposed commit message. The job command records a pending confirmation (`post-pending`) and marks the delivered comment ids handled. You run `review-respond confirm <id>`, which creates a second, fresh throwaway at the PR head as the clean checkout, copies only the reported files from the round's throwaway checkout into it with `wtctl extract` (validated relative paths, regular files, no symlinks, size-capped), commits them there with your git identity through hardened git, pushes fast-forward only to the PR head ref (refusing with `remote_moved` if the remote head changed), posts the replies via pr-comment and removes both throwaways (`reject` removes the round's throwaway too). wtctl never runs git in a throwaway after creating it; review-respond runs hardened git only in the clean checkout, which no untrusted process has written, and no trusted process runs anything in the agent-touched checkout.

### 10.4 Attention and notifications (flow D)

1. Agent state changes fire agent-spawn's `post-state-change` (and `post-escalate`, `post-park`), which are wired directly to `notice-route send --stdin-json` → Slack, Home Assistant, desktop; `supervise` updates the tmux window's status prefix. Standalone sessions use claude-session's own hooks instead.
2. Post-exit policies apply (section 9.3): headless unreported → one automatic resume, then escalation; interactive unreported → parked with `needs_attention`; headless blocked/needs-input → promoted to an interactive window, or parked with `needs_attention` (and its job held) when promotion is off.
3. Held jobs (`post-held`), failed starts (`post-start-failed`) and pending confirmations (`post-pending`) fire their tools' hooks for notification.
4. The awkit dashboard derives attention items from all of these.

## 11. Ticket ranking (ticket-queue)

1. **Eligibility filters:** status, pointed, current sprint, unblocked according to linked-ticket dependencies, per-board allow/deny lists of parents/epics, unassigned or assigned to the user, and not claimed.
2. **Deterministic scoring:** configurable weights, e.g. priority, sprint membership, prioritized epics, due date, age, labels, assignee (final list decided in the ticket-queue session). `why KEY` explains the score.
3. **Optional model re-rank** of the top N via a configurable command (binding B, default the bundled rank-tickets skill run headless through claude-session with kind `rank`) using per-board free-text goals (e.g. "finish the search rewrite", "important bug fixes") and prioritized epics.
4. **Manual pins and moves** always override.

Goals, prioritized epics and parent filters are per board. A ticket stays claimed while ticket-work works on it (section 5.3), which is how in-flight tickets are excluded without ticket-queue knowing about ticket-work.

## 12. Autonomy and gates

### 12.1 Public defaults and options

| Activity | Public default | Configurable options |
|---|---|---|
| Start an agent on the next ticket | Manual | Automatic (`start --auto` from cron) up to the jobsctl cap |
| Ticket status transitions | Show and confirm | Automatic per status map (`auto_transition: true`) |
| Push branch and open PR | Push branch, open a draft PR (enforced by the implement skill) | Ready-for-review PR |
| Post a review on another person's PR | Draft; one-key accept | Shadow → auto-post via gatectl |
| Approve another person's PR | Never | Shadow → auto-approve via a gatectl policy (risk tiers), per repo, with mandatory attribution |
| Respond to review comments on the user's PR | Fixes left uncommitted in a disposable checkout and replies drafted; the user confirms; review-respond applies the listed files in a clean checkout, commits, pushes and posts | Auto-push fixes, auto-post replies behind an enforced gatectl policy, within hard rules (no off-limits paths, CI green on the previous head) |
| Merge the user's PR | Never automatic | Per-repo auto-merge behind gatectl |
| Create tickets | Interactive, confirm | None (always confirm) |
| Apply improvement proposals | Proposed edits; user accepts | Auto-apply low-risk targets (post-v1) |
| Tear down a worktree | Only clean and pushed (or at the merged head), after the PR is merged (closed-unmerged: no automatic teardown) | `prune` of agents parked longer than N days |

The author's own config relaxes many of these.

### 12.2 Escalation principle

Any autonomous step can be escalated. Claude may at any point run `claude-session report needs-input --reason-file ...`; the session enters `needs-input(escalation)`, `exec` exits 13 when the session ends, the agent is promoted or parked with its job held (section 9.3), and the user is notified. gatectl checks can return `escalate`, and any pre-hook exiting 13 holds its step the same way (section 12.4). Our default skills and the standard instructions `exec` appends say explicitly that escalating is always acceptable and preferred to guessing.

### 12.3 Gates

- **Use.** Gate policies (section 5.1, gatectl) can guard any step of any tool through `pre-` hooks (`gatectl check <policy>` reads the hook payload on stdin; exit 0 allow, 11 deny, 13 escalate), and are used directly by review-watch (auto-post/approve), review-respond (auto-push/auto-reply) and by harness rules (auto-merge). The calling tool records the gate's `decision_id` in its audit entry. Hook payloads carry top-level `tool`, `hook`, `object_type`, `object_id`, `repo` and `labels` (design guide section 8), which policies match on.
- **Timeouts.** Gate hooks with agent checks need long hook timeouts (e.g. 600 seconds). Callers set `gatectl check --timeout` below the hook's timeout, so a slow check escalates (exit 13) rather than being killed and counted as a veto.
- **Combination.** deny > escalate > allow. Script checks run before agent checks, and an agent check can only make a decision stricter. An agent check below its confidence threshold escalates; an agent-check session that fails, times out or ends unreported escalates (never allows). All input JSON is fenced as untrusted in agent checks.
- **Policy states.** Each policy is `off`, `shadow` or `enforced` (`gatectl set <policy> <state>`); new policies start in `shadow`. In shadow, `check` exits 0 and prints JSON with `"shadow": true`, the would-be `"decision"`, `"enforced": false` and a `decision_id`. Exit 0 in shadow means "do not block", never "authorize". A caller that uses a gate to **enable** an automatic action (auto-post, auto-approve, auto-merge, auto-push, auto-reply) must require `"enforced": true` and `"decision": "allow"` in the JSON; otherwise it falls back to the manual default.
- **Track record.** Outcome feedback (`gatectl outcome <id> agree|disagree`) compares the user's action with the gate's (would-be) decision and builds per-policy, per-repo track records that recommend enforcing (QR-13). A **miss** is an `outcome disagree` (or a revert or incident flag) on an enforced decision; on a miss or a revert, an enforced policy is automatically returned to `shadow`. `gatectl decisions --json [--since]` lists decisions.

### 12.4 Confirmations, holds and `--yes`

- **Pre-hook outcomes.** Pre-hooks run in order. Exit 0 continues; exit 13 escalates (the remaining hooks still run); any other non-zero exit vetoes: the step stops immediately and the tool exits 11. If none vetoed and any escalated, the step is held as below. All returned decision ids are recorded.
- **Pending confirmations.** ticket-work and review-respond keep a pending store and support `pending`, `confirm <id>` and `reject <id>` (review-respond also accepts `approve`). When a confirm-by-default action is reached without a human (non-TTY), or a pre-hook escalates, such a tool does not proceed and does not fail: it records a **pending confirmation** (at least `id`, `tool`, `action`, `target`, `created`, `summary`, `expires`; default expiry 7 days), fires `post-pending`, and exits 13. `confirm <id>` re-checks the action's preconditions, re-runs the other pre-hooks (overriding only the escalating hook's verdict), then performs the step; `reject <id>` drops it. The dashboard lists pending confirmations as attention items.
- **Confirm-by-default primitives.** Tools without a pending store exit 13 without proceeding on a non-interactive confirm-by-default action without `--yes`, or on a pre-hook escalation, and leave recording to their caller. These are: forgectl `merge`; pr-comment `review`, `approve`, `reply`, `comment`; ticketctl writes; wtctl `remove` (except throwaway checkouts). ticket-create `create` requires a TTY (exit 13 otherwise).
- **`--yes`.** Automation (cron entries, harness rules, jobs) never passes `--yes` to bypass a confirm default. Callers pass `--yes` to a lower tool only after a human accepted the action (e.g. ticket-work → `ticketctl transition --yes` after the user confirmed; review-watch `accept` → `pr-comment review --yes`), when config explicitly enables it (e.g. `auto_transition: true`), or when an enforced gate allows it (e.g. auto-post). The caller's own documented policy (e.g. agent-spawn teardown → `wtctl remove --yes`) is a valid reason only for local, non-publishing actions that remain subject to safety refusals; it never covers post, approve, merge, push, ticket transition or ticket creation, which always require a human acceptance, a config opt-in, or an enforced allowing gate. The dashboard confirms in its own dialog and then passes `--yes --actor human:<user>`. `--yes` never overrides a safety refusal (exit 20); only a human `--force` overrides `dirty`/`unpushed`, and nothing overrides `live`.
- **Held jobs.** A job that exits 13 is held in jobsctl; the submitting workflow resolves it when it sees the outcome (section 9.3). Only jobs held by a `pre-start` escalation are released by a human (`jobsctl release <id> --override-escalation`), besides jobs a human held with `jobsctl hold`.

## 13. Security

### 13.1 Permissions and environment

- **Permission profiles.** A permission profile is a fragment of Claude Code settings holding only `permissions` and `sandbox` keys, written in JSON or YAML. `exec` expands a fixed set of variables in it (`${CSESSION_DIR}`, `${CWD}`, `${HOME}`, `${GIT_DIR}`) because Claude Code rules need absolute paths. Named profiles live in claude-session's config; each kind names one, with per-kind and per-repo overrides, and `--permission-profile` accepts a name or a file (a value containing `/` or ending in `.json`, `.yaml` or `.yml` is a file). A profile file is read once, at the launch that names it, and snapshotted into the session's private directory; resumes use the snapshot. The profile is injected via `--settings` (QSC-2). Unknown kinds get the most conservative built-in profile (the review profile). Skill-wrapper tools pass the profile file, sandbox level, setting sources and env allowlist they require on every call (`--permission-profile <file>`, `--sandbox required`, `--setting-sources ""`, `--env-allowlist-only`), and each exposes its own config keys that replace these (design guide section 11); a user who wants a more permissive session changes them there, because claude-session never weakens an explicit per-call request.
- **Profile validation and permission mode.** The isolation settings `exec` generates always override profile content. Every run's generated settings set the permission mode explicitly: isolated (third-party-reading or sandboxed) runs always use `dontAsk`, which a profile cannot change; trusted, non-isolated runs use the profile's mode (including `bypassPermissions`), or `default` when they load no user settings (otherwise Claude Code would start in its `auto` mode). File permissions are generated as both `Edit(...)` and `Write(...)` rules, because a `Write` allow rule alone does not permit the Write tool. For isolated runs a profile may not set `sandbox.enabled`, `sandbox.failIfUnavailable`, `sandbox.allowUnsandboxedCommands`, `sandbox.excludedCommands`, `sandbox.autoAllowBashIfSandboxed: true` or `permissions.additionalDirectories`; no profile may name a path under claude-session's state root or `/tmp/csession-<uid>/`, except inside the session's own `$CSESSION_DIR` and temporary directory; a `${...}` variable in profile content that expands empty is an error. Such a profile, isolated `claude_args` outside the allowlist, or an unsafe path fails the launch with exit 12, and adoption re-runs every path check.
- **Unsafe paths, guaranteed.** An isolated session never gets write access to a location from which a later process would run or load code or config on the user's behalf, and never runs a binary from a place it can write: claude-session defines one set of **session-writable paths** (the cwd, the session's `outbox/`, `artifacts/` and `work/`, `write_dirs`, profile write additions and the private temporary directory) and refuses a writable cwd, `write_dirs` entry or profile write addition that is or contains an unsafe write target (among them `/`, `$HOME` and its ancestors, `PATH` directories, the XDG config, data and state homes, the state root, `~/.claude` and any `$HOME/.<name>` directory, except the session's own directories), a `PATH` entry, profile file or plugin dir inside a session-writable path, and a `read_dirs` entry or plugin dir that exposes credential locations. The exact lists, compared by resolved path, are in claude-session `docs/interface.md`, section Isolation; this document restates none of them.
- Public defaults are conservative. The author's config uses bypass permissions everywhere.
- **Permission rules are not a boundary.** Claude Code's permission rules guide the agent but can be evaded from Bash (e.g. through `sh -c`, `git -C` or an interpreter). The OS-level boundary is Claude Code's **sandbox** (bubblewrap and socat on Linux and WSL2, Seatbelt on macOS), which confines Bash's file system and network access. Each kind has a `sandbox` setting: `required` (the sandbox must start; if it is unavailable the launch fails with exit 12 and an install hint, and Bash never runs unsandboxed), `preferred` (use it when available, otherwise warn and rely on permission rules) or `off`. Third-party-reading kinds default to `required`, which is also the baseline for any third-party-reading run: a run whose resolved mode is below it, whatever lowered it (flag, config, repo override, carry-over), is allowed but warned and audited at adoption (`sandbox_lowered`). `rank` defaults to `preferred`. A run's `sandbox_active` is true when its sandbox mode is not `off`, the prerequisites were present at launch (Linux and WSL2: `bwrap` and `socat` on `PATH` and user namespaces usable; macOS: `sandbox-exec`) and the socket path fits. Sandboxed sessions get no `excludedCommands` and cannot run commands outside the sandbox. `exec` checks the sandbox's prerequisites before launch.
- **Setting sources.** Third-party-reading kinds load no user, project or local setting sources by default (`setting_sources: []`): no user allow rules or bypass default, no CLAUDE.md, skills, installed plugins, hooks or MCP connectors, and no user-level `WebFetch` domain rules (which would otherwise also open those domains to sandboxed Bash). The generated `--settings` and the given `--plugin-dir` still apply.
- **Isolation of sandboxed and third-party-reading sessions.** The permission-layer isolation below (`blockReadsOutsideWorkingDirectories`, Edit/Write denies for protected files, the generated `dontAsk` mode and `sandbox.autoAllowBashIfSandboxed: false`, which makes sandboxed Bash follow the allow rules instead of Claude Code's auto-allow default; `--add-dir $CSESSION_DIR` and the report permissions apply to every run) applies when a run is third-party-reading or sandboxed; the sandbox layer applies when the sandbox runs. `kinds --json` and `exec --dry-run` warn when a third-party-reading run would not be sandboxed, and `status` and hook payloads report `sandbox_active`. Such a session can read and write only what its kind allows (the generated rule lists are in claude-session `docs/interface.md`, section Isolation):
  - Reads: Claude Code's `blockReadsOutsideWorkingDirectories` is on, so the session (Bash and the Read tool) sees only its working directories: its cwd and its own `$CSESSION_DIR` (added with `--add-dir`). The sandbox additionally denies reads of the whole file system (`denyRead: ["/"]`) and re-allows only an allowlist: the cwd, the session's own `$CSESSION_DIR`, the system directories (`/usr`, `/bin`, `/sbin`, `/lib*`, `/etc`, `/opt`), the directories of the resolved `bwrap`, `socat`, `git` and `claude` and of claude-session's installation, and the entries below; so no session can read `state.db`, any private directory, another session's secret, prompt or artifacts, or other checkouts and temporary files. The private temporary directory is writable (and so readable) but never listed as read-only, which would break the sandbox's shell and network bridge. Toolchains outside the working directories and the default allowlist (e.g. version-manager installs under `$HOME`, toolchains on other mounts) are made readable, read-only and to Bash only, through the kind's `read_dirs`; `exec` adds its own installation (including its Python environment's prefixes and import paths), the kind's `PATH` additions and, when a git dir was resolved, the git dir and the worktree's gitdir automatically. Each `--plugin-dir` is also added as a working directory (`--add-dir`, the only way the Read tool reaches it) and write-denied in both layers, so bundled skills can read their own reference files but not change them. Plugin contents are trusted code: their hooks run outside the sandbox.
  - Writes: the session's cwd (for review and gate-check, `$CSESSION_DIR/work/`), `$CSESSION_DIR/outbox/` and `$CSESSION_DIR/artifacts/`, plus the kind's `write_dirs` and profile additions. The secret, prompt, standard-instructions, `run.json` and `inputs/` files and the empty stand-ins `gh-empty/` and `empty-gitconfig` are write-denied in both the sandbox and the permission rules; the private directory is never visible, and its Edit/Write deny applies to every run, isolated or not. For third-party-reading kinds, the worktree's Claude project config is write-denied at every depth (`.claude/`, `.mcp.json`, `CLAUDE.md` and `CLAUDE.local.md`, top-level and in subdirectories) through Edit/Write deny rules, with sandbox `denyWrite` for the concrete top-level paths, so a session cannot plant settings, hooks or instructions for a later trusted session in the same worktree; the same Edit/Write denies cover `$CSESSION_DIR` and every `--add-dir`. With no setting sources, planted project or nested skills do not load anyway; `Skill(...)` allow rules are not relied on. Sandbox denies of paths that do not exist yet are honored; single-`*` globs are not, so only concrete paths are generated; wtctl's repo-config baseline is the backstop for nested config (section 13.2 rule 10).
  - **Git directory, read-only.** For every third-party-reading run whose cwd has a git dir, the git dir (and a linked worktree's gitdir in the main clone) is readable but write-denied as a whole, in the sandbox and in the permission rules, and `git status` runs without optional locks. The session can read history and diffs and edit the working tree, but cannot stage, commit, move refs or plant git config or hooks; no list of git internals is needed. (Claude Code's sandbox would otherwise open a linked worktree's common git dir partly writable.) The cwd's own `.git` (file or directory) is always write-denied in both layers. A cwd with no git dir is recorded as such: isolated runs are denied creating `.git` there, and a git dir that appears later refuses the next resume or adoption (exit 12, `git_dir_changed`). claude's environment also carries git hardening (`GIT_CONFIG_COUNT` entries neutralizing `core.fsmonitor`, `core.hooksPath`, `core.sshCommand`, `credential.helper`, `diff.external` and `core.pager`) as defense in depth for the agent's own git commands, which can override it; Claude Code's own git calls are hardened by Claude Code.
  - Each sandboxed session gets a private, short temporary directory, because the sandbox always makes `TMPDIR` writable and the shared default temporary directory holds other sessions' files.
  - The sandbox runs the session's commands in their own process namespace, so other processes' environments and command lines are not visible.
- **Review profile** (public default for `review`, `gate-check` and unknown kinds): sandbox `required` with no network; cwd = `$CSESSION_DIR/work/`; the generated permission mode `dontAsk` (anything not allowed is refused without a prompt; the profile itself sets no mode); Write allowed only under `$CSESSION_DIR/artifacts/`, `$CSESSION_DIR/outbox/` and the cwd (`$CSESSION_DIR/work/`); Bash allowed only for `claude-session report` (so `agent-spawn` and `memoctl add` are denied; the standard instructions have the agent write its summary to a file with the Write tool and pass `--summary-file`); the Agent, Task and Skill tools allowed; WebFetch, WebSearch and all `mcp__*` tools denied; no MCP servers (`--strict-mcp-config` with none); env allowlist; `gh`/`glab` denied, with empty `GH_CONFIG_DIR`/`GLAB_CONFIG_DIR`. The `readonly` profile (used by `rank`) has the same rules, but its sandbox is `preferred` rather than `required`, so it runs (with a warning) where the sandbox is unavailable; `rank` is not third-party-reading.
- **Respond profile** (public default): sandbox `required` with no network, which is what makes `git push`, the user's tmux server and SSH agent and any other network or socket access unreachable; the checkout's git directory is read-only (above), so the agent edits files but never stages or commits. `${GIT_DIR}` is resolved with hardened git (section 13.2 rule 10) at the session's first launch and re-checked on every resume and adoption (a change refuses the launch, exit 12). cwd = review-respond's disposable checkout for the round (`cwd: caller`; a separate clone whose `.git` lies inside the cwd; launching without a git cwd fails with exit 12, `no_git_cwd`). The generated mode `dontAsk`: Bash is allowed (the sandbox is the boundary), with defense-in-depth denies for `git push`, `git remote`, `git config`, `git credential`, `gh`, `glab`, `agent-spawn` and `memoctl add`. Edit/Write are limited to the checkout, excluding its git dir. WebFetch, WebSearch and all `mcp__*` tools are denied; no MCP servers. Environment: allowlist without git-host credentials, plus `GIT_CONFIG_GLOBAL=<empty file>` and `GIT_CONFIG_NOSYSTEM=1`; `SSH_AUTH_SOCK` and `TMUX` unset. The agent reports the changed files and a proposed commit message; review-respond commits on confirm (section 5.3).
- **Isolation of third-party-reading kinds.** Sessions of third-party-reading kinds must not be able to reach the user's tmux server or write any awkit tool's config (`~/.config/<tool>/` for every awkit tool, including `~/.config/awkit/`) (which would let them add hooks or relax other tools' config); the required sandbox and the review and respond profiles enforce this.
- **Environment.** A per-kind env setting controls which variables a session inherits, independent of permission mode:
  - Trusted kinds inherit the caller's environment. Third-party-reading kinds start from an allowlist (default: `PATH`, `HOME`, `USER`, `LOGNAME`, `SHELL`, `LANG`, `LC_*`, `TERM`, `COLORTERM`, `TZ`) plus the kind's `env.allow`.
  - The variables Claude Code needs for its own authentication (`claude_auth_env`, built in and extendable) are always passed when present; Claude's own auth is never stripped. Cloud-provider variables are passed only for the matching provider: `AWS_*` only when `CLAUDE_CODE_USE_BEDROCK` is set, `GOOGLE_*`, `CLOUD_ML_REGION` and `ANTHROPIC_VERTEX_PROJECT_ID` only when `CLAUDE_CODE_USE_VERTEX` is set.
  - claude-session config lists `secret_env: [...]` (e.g. notification webhooks, ticket and home-automation tokens); these are stripped from every kind, including inheriting kinds, unless that kind's config `env.allow` names the variable exactly (a per-call `--env-allow` cannot). Structured config (`kinds`, permission profiles, repos, hooks, `secret_env`, `claude_auth_env`, `claude_args`, the notes command) cannot be set from environment variables; only top-level scalars can.
  - Third-party-reading kinds never receive git-host token variables, get `GH_CONFIG_DIR`/`GLAB_CONFIG_DIR` pointed at an empty directory, and have `TMUX`, `TMUX_PANE` and `SSH_AUTH_SOCK` unset. The user's shell profile may set variables again inside the agent's shell, so the sandbox, not environment scrubbing, is what blocks the SSH agent and tmux.
  - `env.path_prepend` adds directories (e.g. version-manager shims) in front of `PATH`, for sessions started from cron or a tmux server with a minimal `PATH`; `claude_bin` names the `claude` executable when it is not on `PATH`.

### 13.2 Prompt injection (QSC-1)

1. **Fencing.** Untrusted text (PR titles, bodies, comments, ticket descriptions, commit messages, diffs, command output) is fenced with a random nonce: `<untrusted source="..." id="R">...</untrusted id="R">`, with a standing "data, not instructions" rule. Any `</untrusted` inside the content is neutralized (e.g. `&lt;/untrusted`). Every tool that fences follows the same rule (design guide section 12).
2. **Transport.** Untrusted or agent-generated text is never passed in argv or env to any subprocess; it goes through files or stdin. Every argument that can carry such text (bodies, titles, messages, comments, summaries, reasons, payloads, prompts) is accepted as `--<name>-file <path>` or `-` (stdin), never only as an argv string: e.g. `gatectl check --input`, `send --stdin-json` on notice-route and the channel tools, `ticketctl comment/create --body-file`, `pr-comment reply/comment --body-file` and `review --draft-file`, `memoctl add --body-file`, `claude-session report --summary-file/--reason-file`. A jobsctl job's argv never contains such text. Prompt files live under the invoking tool's state dir and are deleted when the run ends; `exec` copies the prompt to `$CSESSION_DIR` and delivers it as a file, with only a trusted bootstrap prompt in argv and the standard instructions in the system prompt (section 8.2).
3. Untrusted content is pre-fetched deterministically before the session, so sessions do not need git-host credentials to read it.
4. Least environment per kind (section 13.1).
5. Deterministic-first gates; an agent check may only tighten a decision (section 12.3).
6. Code from other people's PRs is never executed by default (no install, no tests) unless enabled per repo (`run_pr_code: true`).
7. **Trust tiers.** Tickets from the user's configured boards are semi-trusted regardless of author, and the user's own PRs are semi-trusted: still fenced; git-host credentials not stripped by default. Tickets from external or public trackers are untrusted, as are comments by others on the user's PRs; only comments from collaborators with write access or configured reviewers trigger a respond (section 5.3).
8. **Notes.** The author kind recorded by `memoctl add` is a *claimed* kind read from the env var named by `kind_env` (default `CSESSION_KIND`; best effort, spoofable); memoctl has no dependency on claude-session. The defenses are: (a) third-party-reading kinds are denied `memoctl add` by their default permission profile; (b) everything `memoctl context` emits is fenced as `<untrusted source="memoctl" ...>`; (c) notes whose claimed kind is third-party-reading or `unknown` are excluded from other kinds' context by default.
9. **Third-party code.** Sessions on third-party code never load that code's project settings or CLAUDE.md: review sessions run with their cwd outside any checkout (the diff is pre-fetched) and with `--setting-sources` excluding project settings. When `run_pr_code: true`, review-run sequences the work so the session never has a checkout: (1) it creates a **throwaway checkout** with `wtctl create --throwaway --ref <sha>` (a separate disposable clone, not a linked worktree; wtctl copies only that commit, as a pack from the local clone when it has it, else by a fetch from the remote with wtctl's configured credentials); (2) it runs the per-repo configured command (e.g. tests) there deterministically, with an env allowlist (no `token_env` variables, empty `gh`/`glab` config dirs) and a timeout, and captures its output; (3) it removes the throwaway checkout; (4) it launches the review session with `--worktree none`, passing the output fenced as untrusted. `--ephemeral` is not used for this. Sandboxing the command (e.g. in a container) is an open topic (section 20).
10. **Repository-controlled config and hooks.** An agent can edit its worktree's git config (and a trusted, unsandboxed agent the clone's shared git dir), so every git command a tool (not an agent) runs on a repository, worktree or checkout an agent may have used uses the **hardened git invocation** below. It was verified against git 2.34 (wtctl's design records each vector it blocks: filter drivers, `remote.<name>.uploadpack`, `insteadOf` rewriting to `ext::` with repository-level `protocol.allow`, `pager.<cmd>`, `log.showSignature` with `gpg.program`, `core.askPass`, submodule config, pointer-file and `core.worktree` redirection, caller environment variables, ancestry forged with replace refs, grafts or a commit-graph, ssh prompts, and repository extra headers and redirects); this list is normative, and every tool that applies it keeps a `live` regression test of it:
    - **Environment built from scratch**, not inherited: `PATH` (the git binary's directory, `/usr/bin`, `/bin`, plus the directories of allowed filter drivers' commands), `HOME`, `LC_ALL=C`, `GIT_CONFIG_NOSYSTEM=1`, `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_TERMINAL_PROMPT=0`, `GIT_ALLOW_PROTOCOL=<the scheme of the URL in use>` for a command meant to contact the network and `none` for every other command, `GIT_NO_LAZY_FETCH=1` for every command not meant to contact the network (honored by git builds that have it; `GIT_ALLOW_PROTOCOL=none` alone blocks the lazy fetch on 2.34), `GIT_NO_REPLACE_OBJECTS=1`, `GIT_GRAFT_FILE=/dev/null/none` (a path that can never exist; `/dev/null` itself prints a deprecation hint) and `GIT_SSH_VARIANT=ssh`; `SSH_AUTH_SOCK` only for SSH network operations (ssh reads `~/.ssh/config` and known hosts from the home directory in the user's passwd entry, not from `$HOME`; that config is user-owned); tokens only as `http.extraHeader` entries passed through `GIT_CONFIG_COUNT`, never in argv. No other caller variable (e.g. `GIT_DIR`, `GIT_EXEC_PATH`, `GIT_CONFIG_PARAMETERS`, `GIT_SSH_COMMAND`, `GIT_TRACE*`) reaches git.
    - **Overrides on every call:** `--no-pager -c core.fsmonitor= -c core.hooksPath=/dev/null -c core.sshCommand="ssh -o BatchMode=yes" -c credential.helper= -c core.askPass= -c core.pager=cat -c diff.external= -c core.attributesFile=/dev/null -c log.showSignature=false -c fetch.recurseSubmodules=false -c submodule.recurse=false -c gc.auto=0 -c maintenance.auto=false -c core.useReplaceRefs=false -c core.commitGraph=false -c http.followRedirects=false`, plus `--no-textconv` where it applies and `--no-ext-diff` on every diff-family command (`diff`, `show`, `log -p` and the like); `--no-ext-diff` is required for correctness, not only for safety: with `diff.external=` set empty, `git diff` fails (`cannot run`) unless it is passed. `GIT_TERMINAL_PROMPT=0` does not stop ssh's host-key and passphrase prompts; `BatchMode` does, so an unknown host key or a locked key fails instead of blocking.
    - **Filter drivers and extra headers neutralized:** every `filter.<name>` defined in any config git reads gets `clean`, `smudge` and `process` set empty and `required` false through `GIT_CONFIG_COUNT`, and every repository-config key matching `http.*extraheader` (case-insensitive; URL-scoped and wildcard keys included) is blanked by its exact name the same way (a blanket `-c http.extraHeader=` does not clear scoped keys). A tool checking out the user's own code may instead pass a driver's complete definition, including `process`, from the user's global config (wtctl's `create.allow_filters`, e.g. for git-lfs).
    - **Explicit locations:** `--git-dir` (and `--work-tree` for commands in a worktree) are always passed, and `rev-parse --git-common-dir` must return the expected common dir before the tool acts. A tool removing a worktree first verifies the worktree's `.git` file, the `gitdir` back-pointer and `commondir` against its own record, and deletes only the path it recorded, fd-based (each component opened no-follow from the recorded root, the directory's identity checked against the record), never through `git worktree remove`, whose path-based recursion follows a directory swapped for a symlink mid-walk. It deletes the admin entry the same way, only when the admin entry and every directory on the chain to it are on the common dir's device and mount. Tool deletions never cross a mount point or start on one, and neither does any other walk a tool makes of an agent-writable tree: every walk has an anchor (the recorded common dir for admin entries and git-dir listings, the recorded worktree directory for worktrees, the tool's own root for its scratch trees) whose opened directory's `(st_dev, st_ino)` is compared with identities recorded when the tool first recorded the location, never with ones read at operation time (a mount on the anchor or an ancestor would otherwise pass), and then each directory opened on the no-follow chain from the anchor, the walk's root, each directory inside it and each file the walk reads are compared with the anchor's device (and, on Linux, mount id). A mismatch at the anchor, at the root or on the chain refuses the operation; a directory or file inside the tree on another mount is never descended into or read (an unprivileged FUSE mount inside a worktree, on the admin entry itself or on the common dir would otherwise turn the deletion onto any directory the user can write), and reads of agent-writable files are bounded in bytes. Every walk opens entries non-blocking, never reads FIFOs, sockets or devices, and runs in a child process under a hard deadline that the tool enforces by killing that exact process; an expired deadline fails safe (the check is incomplete, the operation refuses). A file system that presents a new device number after a reboot makes these operations refuse until a human re-records the identities, after seeing where each location is mounted; tools never re-record an identity by themselves, and never accept one on a FUSE file system. These defenses target planted configuration and mount tricks that would make a tool itself destroy or misread data; a trusted, unsandboxed agent can always delete or alter the user's files directly, so deliberate file-system-level sabotage by such an agent is out of scope beyond these checks. Tools never run `git worktree repair` on clones agents used (it repairs every admin entry, including planted ones, and writes `.git` files where they name); a tool that must fix the pointers rewrites the two it recorded itself.
    - **No repository discovery:** a command that runs outside any repository (`clone`, `init`, `index-pack` of a tool-built pack) uses a fresh private directory as its cwd with `GIT_CEILING_DIRECTORIES` set to that directory's parent (git ignores a ceiling equal to its cwd), so git never discovers and reads an ancestor repository's config (`url.*.insteadOf`, `http.proxy`, `http.cookieFile`); a network listing command (`ls-remote`) runs with an explicit `--git-dir` of a tool-owned repository, never with no repository.
    - **Lazy fetching and local paths.** A promisor remote planted in an agent-writable repository runs its `uploadpack` command whenever git reads a missing object (e.g. during `status`, `worktree add`, `cat-file`, `pack-objects`, or a thin-pack `index-pack --fix-thin` even with nothing tampered), and a `-c` override cannot replace it. `GIT_NO_LAZY_FETCH` is honored only from git 2.45.1 (and in some maintenance and distribution backports), while `GIT_ALLOW_PROTOCOL=none` blocks the lazy fetch on every version, so every command a tool runs against a repository an agent may have written runs with `GIT_ALLOW_PROTOCOL=none` (plus `GIT_NO_LAZY_FETCH=1`), with no exception. Objects are moved into or out of such a repository only as packs the tool builds and indexes itself (a non-thin pack, indexed outside any agent-writable repository or in a fresh tool-owned one), never by `fetch`, `clone` or `push` run against it; review-respond's commit and push happen in its clean throwaway, which no agent wrote. Local repositories are addressed by a plain absolute path, never a `file://` URL: a planted `remote.<file-url>.uploadpack` applies to the URL form, while git ignores remote names that begin with `/`.
    - **Fetches.** A tool never runs a network fetch in an agent-writable repository: a fetch by URL still reads that repository's `remote.<URL>.*`, URL-scoped `http.<url>.*` and negotiation config (verified: local branches force-moved, a shell command run, a file overwritten, the token sent through a proxy or across a redirect), and no set of overrides closes that class. Network fetches run in a **tool-owned repository** (wtctl's mirror) whose config only the tool writes, from a URL the tool recorded (never a remote name, never the clone's current remote config) and verified to be unchanged by the clone's `insteadOf` rewriting (`ls-remote --get-url`, a local command). Objects reach an agent-writable clone only as a pack built in that repository and installed by the tool (Lazy fetching, above). `status` uses `--ignore-submodules=all`. wtctl's `docs/interface.md`, section Mirror, holds the detail.
    - **Network operations** (fetch, remote listing, clone, push) run under a timeout the tool enforces (killing the process group on expiry; wtctl's `network_timeout`, and `clone_timeout` for clones and full fetches), with `-c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60`.
    - **Reachability.** The replace-ref, graft and commit-graph settings above stop forged ancestry through git's metadata, but an agent that can write the shared object store can still substitute a commit object under its own sha, which git does not re-hash on ordinary reads. A tool that deletes anything because work "is pushed" therefore makes the reachability decision in its tool-owned repository, never in an agent-writable clone: the remote tips are that repository's branches after a successful refresh from the recorded URL (never refs an agent can write), a commit counts only when it exists there and is an ancestor of a tip (existence alone is not enough: a force-pushed-away commit stays as an object), every lookup runs with protocols `none` so a missing object cannot trigger a lazy fetch, and ancestry is verified by content: wtctl re-hashes every commit on a parent path from the tip to the commit and treats any mismatch, missing object or refresh failure as not pushed (wtctl's `docs/interface.md`, section Reachability). This is why wtctl's reachability checks can be trusted.

    claude-session exports defense-in-depth equivalents into the session's environment for third-party-reading runs (section 13.1); the agent's own git commands can override them. In addition, wtctl records a **baseline** when it creates a worktree (after bootstrap, so the project's own setup is part of it) or adopts one it did not create. Its items fall into two classes. **`git` class:** the clone's config and `${GIT_DIR}/config.worktree` and every config file they include (`include.path`, `includeIf`), parsed, minus routine branch and remote tracking keys (such as `branch.<b>.merge` or `remote.<r>.fetch`; the exact, fail-safe exclusion list is wtctl's); the hooks dir and the effective `core.hooksPath` dir; `objects/info/alternates`; each submodule's `modules/**/config` and `modules/**/hooks`, both under the clone's common dir and under the worktree's own admin entry (`<admin_dir>/modules/**`, where a linked worktree keeps its submodules' git dirs); the worktree's own admin entry (`worktrees/<name>/commondir`, `gitdir` and `config.worktree`; other worktrees are covered by their own records); and `info/exclude` and the effective `core.excludesFile`. **`claude` class:** the worktree's Claude project config (`.claude/`, `.mcp.json` and any `CLAUDE*.md`, recursively at any depth, including inside ignored and dependency directories). The exact item list and the digest are specified in wtctl's `docs/interface.md`, section Baseline. wtctl `remove` refuses (exit 20, `reason: repo_config_changed`) if any `git`-class item changed, before running any git command in the worktree other than the hardened integrity read, and reports `claude`-class changes as a warning (Claude project config cannot run during wtctl's hardened removal); `wtctl baseline check` refuses on a change in either class, and agent-spawn uses it to refuse resuming an agent in a kind that is not third-party-reading after a third-party run on its worktree (section 9.4) and before any tool-performed push from that worktree. Only a human re-records a baseline (`wtctl baseline accept`, after inspecting the change). claude-session's own git calls (resolving the git dir and the origin lookup for the derived `--repo`; all read-only) and review-respond's commit and push on confirm use the same hardened invocation. The baseline is the backstop for what claude-session's write denies cannot guarantee (nested Claude project config, hook managers configured inside the worktree). It detects, but does not prevent, changes by trusted agents, which may write their git dir; a trusted agent that lies about a human actor can also re-record it (residual risk). Pushes use `push --no-verify` to a fully specified remote URL (never a remote name), verified to be unchanged after `insteadOf` rewriting, and an explicit ref; they are fast-forward only and never forced. A fast-forward push from a shallow throwaway works and leaves the remote unshallow (verified, wtctl spike F1).

Residual risks, acknowledged: (a) a third-party-reading run without the sandbox (the user lowered `sandbox`, or `preferred` found it unavailable) relies on evadable permission rules; claude-session warns and reports `sandbox_active`. (b) In trusted, unsandboxed kinds the agent can run `hook-event` itself and forge state transitions for any session; trusted kinds are trusted by definition. (c) Claude Code's sandbox leaves small traces on the host (empty `config.worktree` files in the git dir, a `.claude/.cc-writes/` directory) and makes `git add -A` fail inside the sandbox; they carry no code, and wtctl's baseline ignores them (an empty or key-less config file contributes no items, and `.claude/.cc-writes/` is excluded). (d) Prompt injection can still steer a session's own outputs (its working-tree changes, proposed commit message, summary and artifact), which is why those outputs are untrusted, reviewed or gated before any external action. (e) A secret the agent can read could be leaked in an encoded form that the `contains_secret` check does not recognize. (f) Git hook managers configured by files inside the worktree (e.g. husky or a pre-commit config) can be edited by a third-party session and would run on a later trusted commit; denying them would break normal work, so the guarantee is the baseline check before tool git operations and the hardened flags tools use. (g) There is no launch-recursion guard beyond hook selectors: a `pre-launch` hook that launches sessions must exclude their kind (`exclude_kinds`), or it recurses until its timeout. (h) An agent can create nested git repositories (for example `sub/.git`) inside its writable cwd; the git-directory denies cover only the worktree's own git dir, so tool-performed git operations never run inside an agent-touched checkout (review-respond applies the listed files in a second, fresh throwaway that no agent has touched). (i) Forking or resuming a trusted session into a third-party-reading kind carries its conversation, possibly including secrets the trusted agent read, into a context driven by third-party text; `contains_secret` catches only configured literal values. This is the designed respond flow: the disposable checkout limits file access and the sandbox has no network.

### 13.3 Credentials (QE-9)

Environment variables only, named in each tool's config (`token_env`; per host for forgectl and wtctl), or, for wtctl, a configured token command (`hosts.<host>.token_command`, an argv list run without a shell, e.g. the forge CLI's `auth token`; its output is never logged, stored or put in git's argv). Populating the environment is the user's concern (shell profile; cron entries may source a user-owned env file). `gh`, `glab` and `claude` use their own login stores. Secrets are never logged and never appear in hook payloads or `--json` output; job output tails are masked (best-effort; see jobsctl's Residual risks). Hook processes inherit the tool's environment minus its configured `token_env` variables by default. Sessions lose claude-session's `secret_env` variables unless their kind allows them (section 13.1).

## 14. Audit (QSC-3)

- Every tool that takes an external action (post, approve, merge, push, transition, create) appends to `~/.local/state/<tool>/audit.jsonl`: timestamp, actor, decision id or ids (if gates were involved), target, action, input hashes (e.g. PR head SHA, config hash), result. The record format is a public contract (`schemas/audit.json`).
- Every external-action command accepts `--actor` and a repeatable `--decision-id`. The default actor is `human:<user>` when run from a TTY, otherwise `auto:unknown` unless passed; `<user>` is config `me.name`, defaulting to the OS username. Automatic callers pass e.g. `auto:<policy>` with the gate decision id, and the dashboard passes `human:<user>` for actions the user triggers.
- Agent pushes and PR creation happen inside sessions via `git`/`gh`, not through a tool (except review-respond's audited commit and push on confirm). They are attributed by commit trailers and the PR body (added by the implement skill), recorded in the session transcript, and ticket-work `sync` writes an audit entry when it links the PR.
- gatectl records every decision, including shadow decisions and outcomes.
- **Attribution footers.** Artifacts carry attribution where the platform allows (review/comment/approval footer, PR body, commit trailer), e.g. "Drafted with AI assistance · posted by <user> after review · commit <short-sha>" or "Posted automatically under policy <name> · no human review". Every footer template includes the fixed marker `<!-- pr-comment:v1 -->`; the marker is owned by pr-comment, which writes footers; tools that detect awkit-authored content (review-watch's "already reviewed yourself" check, review-respond's ignore rules) match the marker only on content authored by the user's own account. Public default: on. Attribution on automatic actions is mandatory even when the general footer is off.
- Some compliance regimes require a real person to sign off under their own account; hence approvals never default to automatic and attribution names the accepting human.
- `awkit audit` merges all logs into one timeline. Each tool has an optional `export` for shipping its log to a shared location.
- Retention: forever by default. Tamper-proofing is out of scope.

## 15. Notifications

- Channels: Slack and Home Assistant are primary; desktop (Windows toast on WSL) is nice-to-have; tmux window status prefix; the awkit attention list.
- **Default wiring is direct.** Producers are tool hooks: agent states (agent-spawn `post-state-change`, `post-escalate`, `post-park`; claude-session hooks for standalone sessions), review drafts (`post-draft`), held and failed jobs (`post-held`, `post-fail`), failed starts (`post-start-failed`), pending confirmations (`post-pending`), PR events (`on-<event>`). Users wire these hooks to `notice-route send --source <tool> --stdin-json`. Harness rules do not send notifications by default. Session-state hook payloads carry the run kind and its `reads_third_party` flag; notification templates exclude the report summary and reason of third-party-reading kinds by default (they are untrusted text). Wire either agent-spawn's or claude-session's state hooks to notifications, not both.
- Channel tools take `send --stdin-json` (title, message, level, link) and escape platform markup; notice-route always calls them that way. Levels are ordered `info < warn < action < error`. notice-route handles routing rules, quiet hours and dedup (section 20); channel tools only deliver.

## 16. Shared notes

memoctl holds uncommitted knowledge that agents leave for each other (e.g. "the integration tests need the local queue running", "module X is mid-refactor on another branch"). Agents write with `memoctl add --body-file`; sessions of kinds with `notes_context: true` receive relevant notes at startup (not on resume or clear, by default) via the injected SessionStart hook calling `memoctl context`, fenced as untrusted, and notes with a third-party-reading or unknown claimed kind are excluded by default (section 13.2 rule 8). Storage, format and pruning are decided in the memoctl session.

**Context contract (binding B).** claude-session runs the configured `notes_context_cmd` (an argv list, default `memoctl context`, run without a shell) and appends `--repo=<repo-id>` as one token (when known) and one `--label key=value` per session label. The repo-id grammar (lowercase host, optional `:port` for a non-default port, then `/` and path segments of `[A-Za-z0-9._-]`) and the label grammar (section 8.1) restrict values to identifier characters, so these arguments never carry free text. The command prints plain text on stdout and exits 0 (with or without output) or 10 (nothing to show); both are success, and any other exit is logged as a warning. It never prompts. claude-session fences the output itself, whatever the command did, caps its size and run time, and starts the session without notes if the command is missing or fails.

## 17. Testing (QD-2)

- **Per tool:** unit tests; every external boundary (subprocess and HTTP calls to `gh`, `glab`, `tmux`, `claude`, Jira and so on) goes through one small gateway module that tests replace with fakes; golden-file tests for `--json` output; output validated against the tool's own `schemas/`.
- **Cross-tool:** an end-to-end smoke suite in the `awkit` repo runs real tools against fake binaries (`gh`, `glab`, `tmux`, `claude`) placed first on `PATH`, returning canned output and logging invocations. Fake bins are copied per repo, not shared.
- **Real-world:** optional, manually triggered tests against a sandbox GitHub repo and real `claude -p`; never in CI. Tests that need a real model or real credentials carry the pytest marker `live` and are deselected by default; CI never holds model or host credentials, so no LLM call ever runs in CI.
- **Skills:** small eval cases where useful; not required for v1.
- Every repo has `make verify` (ruff lint and format check, pyright, pytest without `live` tests, markdown lint with `pymarkdownlnt`). CI runs the same target (section 18.8).
- **Platforms in CI:** Linux only. macOS compatibility of shareable tools is checked locally or manually, never as a CI gate.

## 18. Development process

### 18.1 Interface first (QD-4)

Each tool's first deliverable, before implementation, is its interface spec, committed in its repo as `docs/interface.md` together with `schemas/`:

- CLI surface (commands, flags, exit codes and refusal reasons);
- `schemas/` (JSON Schema for every `--json` output and every hook payload, plus `config.json`, `audit.json` and `log.json`);
- hook names and when they fire;
- config shape (with an example config);
- for skill-wrapper tools, the skill slot's inputs and artifact format.

Dependent tools code against that spec and their own fakes. Reading a sibling repo's spec by local path or URL is fine, and a dependent may copy a sibling's schema files into its tests (pinned to a version); importing them is not allowed.

### 18.2 Order

1. Interface design for all L1 tools, in parallel.
2. Interface design for L2, then L3, then `awkit` (each can start once the interfaces it depends on exist).
3. Implementation proceeds in parallel as soon as the interfaces a tool depends on are committed.

Priority (QG-2): the **review slice** first, the **ticket slice** in parallel. The shared base (`claude-session`, `termctl`, `wtctl`, `agent-spawn`) is the critical path for both.

| Slice | Tools (dependency order) |
|---|---|
| Base | claude-session, termctl, wtctl → agent-spawn; jobsctl |
| Review | forgectl → pr-comment → review-run → review-watch; then gatectl, pr-watch |
| Tickets | ticketctl → ticket-queue → ticket-work (needs base + forgectl + pr-watch) |
| Notify | slack-notice, ha-notice, desktop-notice → notice-route |
| Response | review-respond (needs base + pr-watch + pr-comment) |
| Support | memoctl, ticket-create |
| Harness | awkit |
| Post-v1 | session-audit, self-improve |

### 18.3 Versioning, releases and the interface registry

- **Semver, driven by commit messages.** Every commit on `main` is a squash-merged PR whose title is a [Conventional Commit](https://www.conventionalcommits.org) header (`type(scope)?!?: title`). python-semantic-release derives the next version from the commits since the last tag:

  | Commit type | Bump |
  |---|---|
  | `feat` | minor |
  | `fix`, `perf`, `chore`, `refactor`, `build` | patch |
  | `docs`, `test`, `ci`, `style` | none |
  | any type with `!`, or a `BREAKING CHANGE:` footer | major (minor while on 0.x) |

- **0.x until stable.** Every tool starts at `0.0.0` and stays on 0.x (`allow_zero_version = true`, `major_on_zero = false`). `!` is not used until the tool is usable, stable and ready to release; reaching 1.0.0 is a deliberate breaking-change commit. Each tool's planning stage writes a **version roadmap** (what qualifies it for 1.0, 2.0, …) in its `docs/plan.md`.
- **Release on bump.** On every push to `main` that produces a bump, the release job: bumps the version in `pyproject.toml` and refreshes `uv.lock`; adds the commit titles to `CHANGELOG.md`; commits `chore(release): vX.Y.Z`; tags `vX.Y.Z`; builds the wheel; and creates a GitHub Release with the wheel attached, all in one job. It pushes with a token from the org's release GitHub App, the only bypass actor on `main` (section 18.6). Installing a specific version is `uv tool install git+https://github.com/agent-workflow-kit/<repo>@vX.Y.Z`.
- **Interface changes.** A breaking change to a tool's CLI, `--json` output, hook payloads or config schema is, before 1.0, a `feat` commit (minor bump) whose title names the break (it becomes the changelog line; details go in the PR body); from 1.0 on it is a `!` commit (major bump). Either way the session updates the interface registry.
- `awkit-docs/interface-registry.md` lists each tool, its current version, a link to its interface spec (`docs/interface.md`), and its known consumers. A session changing an interface checks its consumers first.

### 18.4 Repo scaffold (QD-5)

Every repo follows the layout in design guide section 15: `README.md` (purpose, layer, dependencies with binding types), `CLAUDE.md` (links to awkit-docs and the design guide; the open-source rule; scope rules), `docs/interface.md` (the interface spec), `docs/design.md` (seeded from this architecture with the tool's constraints and open topics from section 20), `docs/plan.md` (implementation plan and version roadmap, written in the tool's planning stage), `schemas/`, `config.example.yaml`, `pyproject.toml` (including the python-semantic-release configuration), `src/<package>/`, `tests/`, `Makefile` (`verify`), `CHANGELOG.md`, `LICENSE` (MIT), `.github/` (caller workflows, `dependabot.yml`, PR template), and `plugin/` for tools that bundle skills.

### 18.5 Packaging (QD-1, QD-3)

Python tools install with `uv tool install git+https://github.com/agent-workflow-kit/<repo>` (append `@vX.Y.Z` for a release). A non-Python tool must install with one documented command and follow the same design guide. Each README lists required sibling tools with their install commands, and a missing sibling produces a clear error naming the install command. Whether awkit-docs provides an install-all script is decided in the awkit (harness) session. All repos are MIT-licensed, "Copyright (c) 2026 agent-workflow-kit contributors".

### 18.6 Repository workflow

- **Hosting.** All repos are public in the free GitHub organization `agent-workflow-kit`, including `awkit-ci` (shared CI) and `awkit-docs`.
- **Work happens in git worktrees,** never in a repo's main checkout. Branches are named `<type>/<short-slug>` (e.g. `feat/session-report`).
- **Every change reaches `main` through a PR.** The PR title is the Conventional Commit header that becomes the squash commit, the version bump and the changelog line (section 18.3).
- **Merge settings (every repo):** squash merge only (merge commits and rebase merges disabled); squash commit message defaults to the PR title; head branches are deleted after merge.
- **Ruleset on `main` (every repo):** pull request required; required status checks (the CI workflow and the PR-title check) must pass; no direct pushes, force pushes or deletions; 0 required approvals (GitHub does not allow approving one's own PR; the maintainer's local review replaces approval). The org's release GitHub App is the only bypass actor.
- **Merging.** The maintainer reviews locally and merges with the `awkit-ci` helper `scripts/pr-merge <repo> <pr>`, which runs the local private-content guard on the PR (section 18.7), waits for all checks to pass, then squash-merges. An agent session opens PRs but merges only on the maintainer's explicit instruction for that PR.

### 18.7 Private-content guard (local only)

The author's machine holds private material next to these public repos, so a local guard blocks it from leaking. It is deliberately not part of any repo or CI (its denylist would itself be private).

- The guard script and its denylist live in the author's local working folder, outside every repo. Each local clone points `core.hooksPath` at the guard's hook directory; this is local git config, never committed, and also covers worktrees.
- Hooks: `pre-commit` (staged diff and new file names), `commit-msg` (the message, which matters because PR titles become changelog lines), `pre-push` (every commit being pushed).
- `guard text <file|->` checks text that never passes through git (PR titles and bodies, issue and review comments) and is run before `gh pr create` or any comment; `guard pr <repo> <pr>` checks a PR's diff, title and body and is run by `pr-merge`.
- Contributors without the guard are unaffected; contributions from others are checked by `guard pr` at merge time. GitHub secret scanning still covers credentials for everyone.

### 18.8 CI and security

- **Shared CI** lives in the `awkit-ci` repo as reusable workflows; each repo has thin caller workflows referencing them by tag or SHA. Every third-party action is pinned by commit SHA, and Dependabot keeps pins and dependencies current.
- **On every PR:** PR-title lint (`amannn/action-semantic-pull-request`, allowed types as in section 18.3); `make verify` on Python 3.12 and 3.13; JSON Schema validity of `schemas/` and validation of `config.example.yaml` against `schemas/config.json`; markdown lint; link check (lychee); dependency review; actionlint and zizmor when workflows change. A newer push cancels older runs for the same PR. Docs-only changes skip the test job but still report the required checks.
- **On push to `main`:** the same checks, then the release job (section 18.3).
- **Weekly:** OpenSSF Scorecard.
- **GitHub security features (every repo):** Dependabot alerts and security updates; Dependabot version updates for the `uv` and `github-actions` ecosystems (weekly, grouped); CodeQL default setup (Python and Actions); secret scanning with push protection; private vulnerability reporting.
- **Runners:** standard Linux runners only.

## 19. Scope

### 19.1 v1 is done when (QG-3), on the author's WSL machine

1. **Review slice:** review-watch (cron) picks up a review request, runs review-run headless with the configured skill, drafts, and notifies via Slack/Home Assistant; one-key accept posts the review via pr-comment with a footer; re-review works on re-request.
2. **Ticket slice:** `ticket-work start` takes the top of ticket-queue (filters, scoring, optional re-rank), transitions the ticket, launches an interactive agent in its own tmux window and worktree; the agent brainstorms, implements, opens a draft PR and reports done; the window closes; `sync` transitions the ticket on merge.
3. **Review response:** a new comment on your PR resumes a fork of the same session in a new window; it makes the fixes in a disposable checkout and drafts replies; you confirm, and they are committed, pushed and posted.
4. **Base:** the jobsctl cap is enforced and reorder works; needs-input and done notifications are routed; the awkit dashboard shows the attention list and chains and drills into tool TUIs.
5. **Every tool works standalone** with README, `schemas/`, tests and safe public defaults.

### 19.2 Non-goals for v1 (QG-6)

iTerm or other terminals; GitHub/GitLab issues or other ticket providers; external docs and documentation drift catch-up; auto-approve or auto-merge switched on (mechanisms exist, shadow only); auto-applying improvements; multi-user or team features; a web UI; cloud execution; tamper-proof audit; secret stores (env only); placement rulesets beyond a shared session with a window per agent; spend enforcement beyond review-watch's optional, off-by-default daily cap (spend is analytics only, QR-14).

## 20. Deferred design: constraints and open topics per tool

Each tool's design session starts from this list (scope `M:<tool>` in the author's decision log). **Constraints (decided)** are tool-internal decisions the session must honor; **open topics** are for the session to decide. Cross-tool contracts are in the body of this document and are not repeated here.

### awkit

- Constraints (decided): none (the harness contracts are in section 7).
- Open topics: tool registry/adapter format details, harness state graph schema, harness-level reconcile, rules syntax, rule-action retry count, dashboard panels and actions, dashboard style, where the dashboard runs, when-to-merge rule, TUI internals, change detection details.

### forgectl

- Constraints (decided): none.
- Open topics: backend abstraction, GitLab re-request detection, edge cases (forks, stacked PRs), head-match option per backend for `merge --auto --expected-head`.

### ticketctl

- Constraints (decided): none.
- Open topics: provider interface for future sources, JQL/filter config, write safety flow details, own client vs invoking user-installed tools.

### wtctl

- Constraints (decided): "dirty" means any tracked change or any untracked, non-ignored file; ignored files are listed in the refusal unless they were created by `bootstrap`. `remove` fetches first. The stash check covers only stash entries based on the worktree's branch. The pushed check exempts the worktree's own branch when HEAD equals `--merged-head` or is reachable from a remote ref. Refusals exit 20 with a `reason`.
- Constraints (decided, wtctl design session 2026-10-30): `create --throwaway --ref <sha>` runs `git init` and fetches only the given sha, never cloning all local refs and objects, and persists no credentials; ignored files that bootstrap did not create and that match no configured disposable pattern count as dirty, and any nested git repository does; the pushed check uses only remote state fetched from the URL recorded at create (since the safety check, into wtctl's own mirror); wtctl owns the repo-config baseline and the safe-extraction rules (`extract`).
- Constraints (decided, wtctl review pass 1, 2026-10-30): the pushed check takes the remote tip shas from a source no agent writes (since the safety check, the mirror's branches after a refresh; never the clone's refs) and verifies ancestry by content before trusting it (any mismatch, missing object or fetch failure counts as unpushed); the baseline is recorded after bootstrap and splits into `git` and `claude` classes, and `remove` refuses only on `git`-class changes; default locations lie under one visible root outside hidden and XDG directories; adopted records carry reference-counted holders.
- Constraints (decided, wtctl review pass 2, 2026-10-30): holders are allowed on owned and adopted records and `remove` refuses a record held by another holder (`held`; a human `--force` overrides); removing an adopted worktree without a human exits 13; `remove --dry-run` is the same as `status` (which takes `--merged-head` and `--holder`); reconcile settles a `creating` record only under its per-record lease, never by age; the shallow push from a throwaway is verified (spike F1).
- Constraints (decided, wtctl safety check, 2026-10-30): network git for reachability runs only in a wtctl-owned treeless mirror per clone, and the user's clone is never the target of a network fetch (user decision); wtctl deletes worktrees and admin entries fd-based and never runs `git worktree remove` or `git worktree repair`; tracked files hidden by assume-unchanged or skip-worktree fail the dirty check.
- Open topics: none; resolved in the wtctl design session (2026-10-30) and recorded in its `docs/design.md`.

### termctl

- Constraints (decided): `open` returns a stable id; callers address panes by id, not by name. Outside tmux it targets the default server socket (configurable) and creates the session if missing.
- Open topics: none; resolved in the termctl design session (2026-10-30) and recorded in its `docs/design.md`.

### claude-session

- Constraints (decided): `hook-event` only records state under the session lock (exceptions in section 8.2); lifecycle hooks are fired by `exec`. Pending runs (prepared by `start`, new or resumed) that no wrapper adopts within the configurable grace period end `not-started` (`never_adopted`), never `lost`; the retention period after `forget` is configurable; session directories of sessions that are not forgotten are kept. The session secret file is mode 0600 in `$CSESSION_DIR`; the stored copy is compared in constant time. The size cap for `--summary-file`/`--reason-file` is configurable. Taint is recorded per session and never cleared.
- Open topics: none; resolved in the claude-session design session (2026-10-29) and recorded in its `docs/design.md`.

### jobsctl

- Constraints (decided): jobs run detached under a per-job shim that records exit status and output tail; `jobsctl run` only starts jobs up to the caps and reaps finished shims; it can run as a cron pass or as a loop. Output tails are masked per `mask_env`.
- Constraints (decided, jobsctl design session and review passes 1 to 3, 2026-10-31): the shim runs `pre-start` hooks while holding the job's slot; jobs get jobsctl's allowlisted base environment, never the starting process's whole environment, and `--pass-env` values come only from the user's env file that every pass loads; a job waiting for an automatic retry stays queued; a SIGTERM that was not a `cancel --force` ends a job failed (`terminated`), not canceled; the shim starts each job in its own process group and may signal that group after the exact PID (section 3.4); a job whose shim died but whose process lives keeps its slot and is never killed automatically; `retry` keeps the job id and also requeues a job held after exit 13 (review pass 2); allowlisted environment values come from the trigger chain, the env file is a trust anchor and output masking is best-effort (review pass 2); jobsctl has no repo notion and no per-repo overrides (its queue is the scoping unit; design guide section 5).
- Open topics: none; resolved in the jobsctl design session (2026-10-31) and recorded in its `docs/design.md`.

### gatectl

- Constraints (decided): policy states are `off | shadow | enforced`; new policies start in `shadow`; auto-disable returns an enforced policy to `shadow`. Agent checks run with kind `gate-check`.
- Open topics: policy file format, agent check contract, outcome workflow and recommendation thresholds, sources of after-the-fact failure signals (e.g. a later revert of an allowed change).

### memoctl

- Constraints (decided): no dependency on claude-session (Uses: none); the author kind is a claimed kind read from the env var named by `kind_env`, and its defenses are those of section 13.2 rule 8.
- Open topics: storage, format, keys, pruning, context selection.

### slack-notice, ha-notice, desktop-notice

- Constraints (decided): none.
- Open topics: payload shape, channel config, per-platform escaping.

### pr-watch

- Constraints (decided): the first poll after `watch add` records a baseline and emits no events, except terminal states (`merged`/`closed`) already reached; events are retained at least 30 days (configurable); a watch ends when its last owner reference is removed, and watches auto-expire N days after merge or close.
- Open topics: polling cadence, change detection, hook payloads, cursor encoding.

### pr-comment

- Constraints (decided): none.
- Open topics: review-draft file format, re-anchoring algorithm, footer templates.

### ticket-queue

- Constraints (decided): the claim TTL applies only to claims not renewed and is configurable; after N consecutive `release --failed` a ticket is auto-skipped and the `post-auto-skip` hook fires.
- Open topics: pool definition per board, scoring weights, refresh cadence, pin persistence, re-rank contract.

### ticket-create

- Constraints (decided): `create` requires a TTY.
- Open topics: draft template, confirm flow.

### notice-route

- Constraints (decided): levels are ordered `info < warn < action < error`; quiet hours drop `info`, defer `warn` and `action` until `notice-route flush`, and deliver `error` immediately; hook-payload sends dedup on source + hook + object id within a window, other sends on source + title; the level comes from the rule template, default `info`; channel tools are always called with `send --stdin-json`; `history --json` lists sent notifications.
- Open topics: rule syntax, dedup window, quiet-hours config.

### agent-spawn

- Constraints (decided): stores each agent's termctl id and `socket_path` and passes `--socket` back on every termctl call (termctl keeps the base name and applies the marker); `supervise` polls `claude-session status` for the status marker (`termctl mark`/`unmark`); tmux-hosted `supervise` loads an env file from agent-spawn's state dir (mode 0600, only kind-allowed variables, never `secret_env` or `token_env` variables, deleted immediately after loading); the repo-config baseline is wtctl's (recorded by `wtctl create` or `wtctl adopt --holder <agent_id>`, compared by `wtctl baseline check` on `show` and before a non-third-party resume, and by `wtctl remove` at teardown); an adopted record is released at teardown with `wtctl forget --holder <agent_id>`, never a plain `forget`; a human clears a `repo_config_changed` refusal with `wtctl baseline accept`; tombstones of torn-down agents are kept for N days (configurable).
- Open topics: which labels and placement name agent-spawn passes to termctl (placement itself is termctl's config), parked cleanup, PATH/env, how secret variables a kind allows reach a tmux-hosted `supervise` without touching disk or argv.

### review-run

- Constraints (decided): with `run_pr_code: true`, the per-repo configured command runs deterministically in a throwaway checkout with an env allowlist and a timeout, and only its fenced output reaches the session; the session never has a checkout (section 13.2 rule 9).
- Open topics: review artifact metadata, default reviewer skill design, subagent depth limit, sandboxing the configured command (e.g. a container).

### review-watch

- Constraints (decided): queue items are keyed on (PR, head sha, review-request instance). The spend cap uses the local timezone; spend is the sum of headless `total_cost_usd`; promoted interactive time is not counted.
- Open topics: review state machine (queued → running → drafted → posting → posted → closed, plus failed), risk tier rules, rounds, staleness, shadow mode, config.

### review-respond

- Constraints (decided): a round is one successful resume or launch delivering at least one new comment (delivered = the resumed session reached `working`); the comment watermark is stored per PR in review-respond; before enqueueing it checks whether the agent is live and does not enqueue while live; comment ids are marked handled only after delivery. The respond permission profile is generated per call from the bundled allowlist profile plus the repo's configured test and build commands. Every round uses `--fork --cwd <new throwaway>`: the first round forks the non-owned agent, later rounds fork the previous respond fork; a plain resume into a new cwd is never used (a plain resume keeps its cwd).
- Constraints (decided, safety re-review 2026-10-29), for `confirm`:
  - **`changed_files` and `deleted_files`** are applied with `wtctl extract` (`--files-from`, `--delete-from`, `--dest <clean checkout>`), whose normative rules are in wtctl's `docs/interface.md`, section Extraction rules: normalized relative paths, no `.git` component compared case-folded, every component opened beneath the throwaway with no-follow semantics, regular files with link count 1 within size caps, a missing listed file is an error, deletions only through the separate list, writes into the clean checkout under the same rules, file modes never copied (an existing file keeps its mode, a new file gets 0644), and nothing written unless every entry validates.
  - **Clean checkout.** The clean checkout is a second, fresh throwaway at the PR head (`wtctl create --throwaway --ref <PR head sha>`) that no agent touches; review-respond runs hardened git (diff, commit, push) only there and removes it afterwards (wtctl's `docs/interface.md`, section Extraction rules, clean checkout for confirm). It is created with `--source remote`, never from the agent-writable local clone's objects: wtctl fetches it over the clone fetch URL (the clone's remote URL, verified against the repo id and `insteadOf` rewriting; wtctl's `docs/interface.md`, section Clone resolution) unless `repos.<id>.clone_url` is set, which, if it names a lagging mirror, can give `ref_not_found`. review-respond pushes to the same clone fetch URL (`fetch_url` from `wtctl locate --json`) with its own credentials. A fast-forward push from its shallow history is verified (wtctl design, spike F1); a push to a real forge remains a live check.
  - **Off-limits paths.** The off-limits path list also applies to manual `confirm`: a round touching an off-limits path is refused unless the user explicitly allows sensitive paths after seeing the full diff, computed in the clean checkout.
  - **Commits** run with `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, `GIT_ATTR_NOSYSTEM=1` and explicit `-c user.name=... -c user.email=...` (plus the hardened `-c` set of section 13.2 rule 10).
  - **Throwaway source.** The round's throwaway is created with `git init` plus a fetch of only the PR head sha (no local clone of all refs and objects of the user's repository); credentials are passed per command and never persisted in the throwaway.
  - **Throwaway removal** is `wtctl remove` of the throwaway record: fd-based, never following symlinks, with no git command run in the round's throwaway; the `pending` display never runs git in it either (diffs are computed in the clean checkout).
- Open topics: detection details, reply drafting, pending-confirmation format, auto-push/auto-reply policy input.

### ticket-work

- Constraints (decided): ticket → repo mapping via config (`boards.<b>.repo` or a component map, giving a repo id that wtctl resolves). PR linking matches the ticket key as a whole token in branch names and searches PRs authored by the user in repos mapped to the board.
- Open topics: status map format, preconditions, stale PR handling, ticket state machine.

### session-audit, self-improve

- Constraints (decided): none.
- Open topics: what is audited, when, output, how improvements are applied.

### All tools

- Constraints (decided): none beyond the design guide.
- Open topics: the "hook feature candidates" list, maintained in `awkit-docs/roadmap.md`.

## 21. Glossary

- **Adapter:** harness-side (or coordinating-tool-side) mapping from a role to a specific tool's commands and output.
- **Agent:** a Claude Code session launched by agent-spawn, identified by its `agent_id` and labels.
- **Agent session role:** the role of running and supervising one coding-agent session; claude-session is its one (Claude-specific) implementation, and higher tools bind to the role (section 3.5).
- **Agent statuses (live / parked / torn down):** *live*: a supervised session for the agent is live; *parked*: no live session, resumable (including finished headless agents); *torn down*: worktree removed and session forgotten, kept as a tombstone for N days.
- **Attention item:** an entry in the dashboard's attention list, derived by `awkit` from tool records and hooks (e.g. an agent's `needs_attention`, a held job, a pending confirmation). Tools never create attention items.
- **Attention list:** the dashboard's list of things that need the user.
- **Attribution footer:** text appended to content posted on the user's behalf, naming who accepted it or which policy acted; always contains the marker `<!-- pr-comment:v1 -->`.
- **Binding (A/B/C):** how a higher tool depends on a lower one (section 3.3).
- **Bypass permissions:** Claude Code's permission mode that skips permission prompts; used in the author's config, never a public default.
- **Capability slot:** a model-driven step filled by a configurable skill.
- **Claim:** a reservation made by `ticket-queue next --claim` or `claim KEY` so a ticket is not handed out twice; held until released, with a TTL only for claims that are not renewed.
- **Coordinating tool:** a tool whose job is to bind arbitrary lower tools together (e.g. notice-route).
- **`CSESSION_DIR`:** the session's agent-visible directory (`sessions/<csession_id>/` under claude-session's state root), exported to the session; it holds `prompt.md`, `prompts/`, the standard instructions, `run.json` (run number, report limits), `inputs/` (per-run `--input-file` copies), the session secret, `outbox/`, `artifacts/`, `work/` (the cwd for `cwd: session-dir`), and the empty stand-ins `gh-empty/` and `empty-gitconfig`. Per-run records and frozen artifacts live in the separate private directory `private/<csession_id>/`, which the session cannot see.
- **`CSESSION_KIND`:** the session's `--kind`, exported to the session by `exec`; memoctl records it as a claimed (spoofable) author kind.
- **Decision id:** the id gatectl returns for each decision; callers record it in their audit entries (`--decision-id`, repeatable).
- **Delivered (review-respond):** new comments count as delivered once the resumed session reached `working`.
- **Draft PR:** a pull/merge request marked as a draft on the git host.
- **Escalation:** pausing an autonomous step to ask for the user's judgment.
- **Fencing:** wrapping untrusted text in nonce-tagged `<untrusted>` blocks with a "data, not instructions" rule (section 13.2).
- **Fork (session):** a new session created by `resume --fork` (`claude --resume <id> --fork-session`) that continues a conversation without changing the original; review-respond's respond agents are forks (section 8.5).
- **Gap:** pr-watch's signal (`"gap": true`, exit 0) that a consumer's cursor is older than the retention window; the consumer re-syncs current state via forgectl and resets its cursor.
- **Gate / policy:** a gatectl decision procedure made of script and agent checks, in state `off`, `shadow` or `enforced`.
- **Hard rules:** review-watch's built-in minimum rules that no gate decision can override (section 5.3).
- **Hardened git invocation:** the normative way every tool runs git on a repository an agent may have used: a clean environment with isolated global and system config, overrides of every executable config key, neutralized filter drivers, explicit git and work-tree dirs, and fetches only from a recorded URL (section 13.2 rule 10).
- **Harness:** `awkit`, the optional top-layer tool that adapts to all others.
- **Harness event:** an event `awkit` derives internally by diffing tool snapshots; never required by tools.
- **Held:** a jobsctl job paused for a human or its submitter, with a hold reason: `exit_13` (its command exited 13), `escalated` (a `pre-start` hook escalated) or `manual` (`jobsctl hold`); its slot is freed; `release` requeues `manual` and (with a human `--override-escalation`) `escalated` holds, `retry` requeues `exit_13` holds, `resolve` closes any held job; held is non-terminal for `--unique-key`.
- **Interface registry:** `awkit-docs/interface-registry.md`, listing each tool's version, interface spec and consumers.
- **Interface spec:** a tool's `docs/interface.md` plus its `schemas/` (section 18.1).
- **Kind:** the explicit `--kind` of a session (e.g. `review`, `implement`), selecting its kind profile.
- **Kind profile:** the per-kind settings in claude-session's config: permission profile, sandbox, setting sources, MCP, env allowlist and overrides, read and write directories, `cwd`, `reads_third_party`, bounds, auto-exit, backstop, `implicit_done`, notes context, model, `claude_args` (section 8.1).
- **Label:** opaque `key=value` metadata stored on objects by lower tools; a multiset per object.
- **Live (agent):** an agent with a live supervised session (see agent statuses).
- **Live (session):** a session in `starting`, `working`, `idle`, `needs-input` or `reported`.
- **Managed block:** the tagged crontab block (`# <tool> managed`) that `awkit cron install` or a tool's `cron install` writes and replaces as a unit.
- **`needs_attention`:** agent-spawn's per-agent attention reason (`unreported`, `escalated`, `blocked`, `failed`, `lost`), cleared by a successful resume, teardown or `ack`.
- **Needs-input reason:** why a live claude-session session waits for the user: `permission`, `question` (AskUserQuestion), `elicitation` or `escalation` (section 8.4).
- **`not-started`:** the final claude-session state of a run that ended in the launch phase (vetoed, escalated or failed before `claude` started), a pending run that was never adopted, or a pending run canceled by `stop` (section 8.4).
- **`notify-tick`:** `awkit notify-tick`, a command tools' hooks call to request an early harness tick.
- **Off-limits paths:** a configurable glob list (by default covering security-sensitive code, CI and build pipeline definitions, agent configuration and instruction files, and review-ownership files) on which review-watch and review-respond never act automatically; both use the same default list and format.
- **Outbox:** the directory in `$CSESSION_DIR` where `report` writes its request for the injected hooks to ingest (section 8.3).
- **Outcome code:** the exit code of a command that waits on a session, describing how the session ended (section 8.3).
- **Owning workflow:** the workflow tool that launched an agent, recorded as label `owner=<tool>`.
- **Parked:** see agent statuses.
- **Pending confirmation:** a recorded confirm-by-default action that was reached without a human (or escalated by a pre-hook), waiting for `confirm <id>` or `reject <id>`; announced by `post-pending` and expiring after 7 days by default (section 12.4).
- **Pending run:** a claude-session run created by `start` (or `start --resume`) that no session wrapper has adopted yet; `exec --session-id` adopts it (section 8.1).
- **Permission profile:** the Claude Code permission settings injected into a session via `--settings`; part of a kind profile, overridable per call with `--permission-profile`.
- **Promote:** resume a headless session that ended blocked or needing input in an interactive window, within the same job and under the same supervisor.
- **Query watch:** a pr-watch watch defined by a query (e.g. `--mine --open`) rather than a single PR.
- **Reconcile:** repair a tool's state against reality (tmux, git, processes, a host) and report what changed.
- **Repo-config baseline:** wtctl's record of hashes of a worktree's repository-controlled config, hooks, git pointers and excludes (`git` class) and Claude project config (`claude` class), taken when it creates (after bootstrap) or adopts the worktree and compared before removal (`git` class only), resume or push (either class) (section 13.2 rule 10).
- **Repo id:** the canonical repo identifier `host/<full project path>`, used in flags, labels and config.
- **Review draft:** review-watch's stored, editable, not-yet-posted copy of a review-run artifact (pr-comment's review-draft format).
- **Risk tier:** review-watch's deterministic classification of a PR from its facts (paths, size, author, repo rules, CI); model output may only raise it.
- **Role:** a job in the tool registry (e.g. `githost`, `tickets`, `notify`) that a configured tool fills.
- **Round:** for review-watch, one review of a PR (re-reviews add rounds); for review-respond, one successful resume or launch that delivers at least one new comment.
- **Run (claude-session):** one execution of a session, from `exec` or a `resume` to exit; reports and outcomes are per run.
- **Run (review-run):** one execution of a review skill on a PR, with its stored artifact and state (`running`, `done`, `escalated`, `failed`).
- **Run loop:** `awkit run` (or the open dashboard), looping ticks with early-tick triggers.
- **Sandbox:** Claude Code's OS-level confinement of the agent's Bash commands (file system and network); required for third-party-reading kinds by default (section 13.1).
- **Session secret:** a random value `exec` writes to the 0600 file `$CSESSION_DIR/secret` at the start of every run (rotated on each run); `report` and self-labeling authenticate with it (section 8.3).
- **Session-writable paths:** the locations an isolated claude-session run may write (its cwd, its `outbox/`, `artifacts/` and `work/`, `write_dirs`, profile write additions, its private temporary directory); defined once in claude-session's `docs/interface.md` and used by every path rule (section 13.1).
- **Session wrapper:** `claude-session exec`, the process that runs and watches `claude`, records its state and exits with the outcome code.
- **Shadow mode:** recording what a gate would decide without enforcing it; exit 0 means "do not block", never "authorize".
- **Skill-wrapper tool:** a thin CLI that gathers context, launches a Claude session with a skill, labels it and collects the artifact (section 5.5).
- **Slice:** a set of tools that together deliver one end-to-end workflow (e.g. the review slice), used to order development (section 18.2).
- **Spike:** the empirical experiment that opened the claude-session design session (section 8.6).
- **Standard instructions:** the report and escalation instructions `exec` passes to every session through the system prompt (section 8.2).
- **State graph:** the harness's label-derived graph of tickets, agents, PRs, jobs and so on.
- **Status map:** per-board config mapping ticket-work events (`pr_opened`, `pr_merged`, ...) to ticket transitions.
- **Status prefix:** the status marker (`termctl mark <id> attention`) `supervise` sets on an agent's window while its session is in `needs-input` or `idle`; termctl's config decides how it is displayed (by default as text in front of the window name).
- **Supervise wrapper:** `agent-spawn supervise`, which runs the session wrapper for an agent and applies post-exit policies.
- **Tainted session:** a session on which a run of a third-party-reading kind has been allocated (or a fork of one); the taint is committed at allocation, before any process starts; automation never resumes it in a kind that is not third-party-reading, and only a human may, explicitly with `--allow-tainted` (section 8.5).
- **Third-party-reading kind:** a kind with `reads_third_party: true` (built-in: `review`, `respond`, `gate-check`); it runs in Claude Code's sandbox (required by default), gets an env allowlist, excluded setting sources, a read-only git directory, a denial of `agent-spawn` and `memoctl add`, no access to the user's tmux server, any awkit tool's config files or other sessions' directories, and taints its session.
- **Throwaway checkout:** a disposable clone (not a linked worktree) at one commit, created by `wtctl create --throwaway` (`git init` plus a fetch of only that sha). review-run uses one only when `run_pr_code: true`, to run a configured command deterministically, and removes it before the review session starts (the review session never has a checkout); review-respond runs each respond round in one and copies the agent's changes out with `wtctl extract` into a second, fresh one (the clean checkout) from which it commits and pushes. wtctl never runs git in a throwaway after creating it.
- **Tick:** one harness iteration of poll → diff → derive events → update graph → rules.
- **Tool registry:** the `roles` map in awkit's config naming which tool fills each role.
- **Torn down:** see agent statuses.
- **Unique key:** a jobsctl `--unique-key`; adding a job whose key matches a non-terminal (including held) job is a no-op that returns the existing id.
