# awkit: Architecture

Status: approved architecture (v1.7), 2026-10-28. Produced from the architecture brainstorming session. v1.5: review-respond lists gatectl as an optional dependency (auto-push / auto-reply decisions). v1.6: renamed cw → awkit; tools unprefixed. v1.7: CI, versioning, release and repository workflow (sections 17, 18.3, 18.6–18.8); review-watch wording, states and defaults rewritten generically.

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
- **Never destroy work.** No tool reverts, resets or cleans files with git. Teardown always refuses live sessions, and refuses dirty or unpushed worktrees unless a human passes `--force`; automation never passes `--force`. Processes are only ever signaled by an exact PID the tool started (verified by PID plus process start time), or through a process group the tool itself created for a hook (section 8.2; design guide section 8). Tool-performed git operations never run repository-controlled hooks or other repository-controlled executable config, and never force-push (section 13.2 rule 10).

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

- Commands: `create [--repo <id>] [--branch <name>] [--throwaway --ref <sha>]`, `list`, `remove [--merged-head <sha>] [--force]`, `bootstrap [--copy-env]`, `locate <repo-id>`.
- Uses: `git`.
- Notes:
  - Owns the repo id → local clone mapping (`repos.<id>.clone: <dir>`, with optional auto-clone). agent-spawn, review-run and ticket-work resolve local clones through `wtctl locate`.
  - Naming conventions are configurable. Dependency bootstrapping (shared package-store settings, per-worktree port/container prefixes) is configurable; env-file copying is opt-in per call (`bootstrap --copy-env`). Supports labels.
  - `remove` is confirm-by-default (section 12.4) and refuses dirty or unpushed worktrees (exit 20, `reason` `dirty` or `unpushed`) unless a human passes `--force`; `--yes` never bypasses that refusal. "Unpushed" means HEAD is not reachable from any remote ref **and** is not equal to a supplied `--merged-head <sha>`; callers pass the merged PR head so squash merges do not block removal.
  - **Throwaway checkouts.** `create --throwaway --ref <sha>` creates a separate disposable clone (not a linked worktree, so nothing run in it can touch the user clone's `.git` hooks or config), detached at the sha. `remove` of a throwaway checkout skips the confirmation and the dirty/unpushed checks.

#### termctl

Terminal placement. tmux backend.

- Commands: `open` (session/window/pane, name, command, cwd), `rename`, `focus`, `close`, `list`, `exists`.
- Uses: `tmux`.
- Notes: Knows nothing about Claude. Placement policy (which session, windows vs panes, naming) is passed in by the caller or configured. v1 placement: one shared session, a window per agent (QRT-4). Outside tmux (e.g. under cron) it targets the default tmux server socket (configurable) and creates the session if it is missing.

#### claude-session

Runs and supervises Claude Code sessions. Terminal-agnostic: it builds and runs the command; the caller decides where. Explicitly Claude-specific: it is the one implementation of the agent session role (section 3.5); higher tools treat it through that role, so another vendor's session tool can plug in later through an adapter (binding C). Its env prefix is `CSESSION_` (design guide section 5).

- Commands: `exec` (the session wrapper around `claude`), `start` (allocates a session and prints the `exec` command line for a caller to place), `resume`, `report`, `status`, `list`, `kinds`, `label add/remove`, `forget`, `reconcile`, `transcript`; internal: `hook-event <event>` (called by the hooks it injects into sessions), `verify-secret <csession_id>` (checks a session secret given on stdin, section 8.3).
- Uses: `claude`; optionally memoctl for session-start context (binding B, `notes_context_cmd`; enabled per kind with `notes_context: true`).
- Notes: `--kind <name>` selects a kind profile from this tool's config. Standalone, it records state and exits with an outcome code; post-exit policies (auto-resume, promotion, parking) belong to agent-spawn. Auto-exit after `report done` is performed by `exec` itself. See section 8 for the full session model. Supports labels on sessions for standalone use; for agents, agent-spawn is the authoritative label store and mirrors agent labels onto the session. Records taint (section 8.5).
- Hooks: `post-state-change` (fired by `exec`, section 8.2).

#### jobsctl

Generic job queue. Owns the concurrency caps (used for "max parallel agents") and the order of work already enqueued (QR-9); it does not interpret what jobs do.

- Commands: `add [--queue Q] [--unique-key K] [--env VAR=value] [--pass-env VAR] [--label k=v] -- <argv...>`, `list`, `show`, `move`, `pin`, `priority`, `cancel [--force]`, `retry`, `hold`, `release [--override-escalation]`, `resolve`, `capacity [--queue Q] --json`, `reconcile`, `run` (runner), `browse`.
- Uses: none.
- Notes:
  - Jobs are stored as argv arrays (no shell). A job's argv never contains untrusted text; submitters pass such text in files. Jobs run with the runner's environment plus `add --env VAR=value` (non-secret values only; they are stored) and `add --pass-env VAR` (the value is taken by name from the runner's environment when the job starts and is never stored). Each job gets `JOBSCTL_JOB_ID`.
  - Named queues with priorities, pin/move/reorder, per-queue caps plus an optional `global_cap`. The workflow tools submit to the queues `tickets`, `reviews` and `respond` by default (configurable in each submitting tool); `global_cap` bounds the total number of parallel agents. `capacity` reports free slots (cap − running − queued).
  - `add --unique-key <key>` is a no-op (exit 0, returning the existing id) if a non-terminal job has that key; held jobs are non-terminal. Callers use keys such as `review:<pr>@<sha>`, `respond:<pr>`, `ticket:<KEY>`.
  - Statuses: `queued`, `running`, `held`, `done`, `failed`, `canceled`. Job exit → status: 0 → done; 13 → **held** (its slot is freed); any other exit → failed. A `pre-start` hook veto (any non-zero exit other than 13) → canceled; a `pre-start` hook escalation (exit 13) → held. No automatic retry by default.
  - **Held jobs.** `resolve <id>` closes a held job. `release <id> --override-escalation` requeues a job held by a `pre-start` escalation and re-runs `pre-start` with the escalating hook's verdict overridden. A job held because its own command exited 13 (e.g. an agent that needs a human) is never released: its submitter resolves it and continues through `agent-spawn resume` (section 9.3). Job commands that launch agents are therefore resume-aware: they look for an existing agent by its `job=` or correlation labels and resume it instead of launching a second one.
  - **Cancel.** `cancel` of a queued or held job closes it as canceled. `cancel` of a running job is refused (exit 20, `reason: live`) unless a human passes `--force`, because a running job may host a live interactive agent; with `--force` the shim sends SIGTERM to the job's exact PID, which every layer below forwards (section 9.2).
  - Stores exit status and the tail of each job's stdout/stderr (`show <id> --json`). Tails mask the values of the env vars listed in config `mask_env` and are documented as untrusted.
  - `reconcile` detects dead job shims (PID plus process start time) and marks their jobs failed with reason `lost`, firing `post-fail`.
  - Hooks: `pre-start`, `post-start`, `post-finish`, `post-fail`, `post-held`. Supports labels; submitters label jobs with the same correlation labels they give the agent.

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
- Notes: Flags and defaults are in section 9.2. Authoritative label store for agents. Owns post-exit policies through its supervise wrapper. Does not use jobsctl. Never notifies directly: it records attention as data (`needs_attention`) and fires hooks (`post-escalate`, `post-park`, `post-state-change`). Agent lifecycle is separate from window lifecycle (section 9). Records repo-config hashes at launch (section 13.2 rule 10) and reports `repo_config_changed` in `show --json`. `resume --fork` records the fork as a new agent (section 9.4).

### 5.3 Layer 3: workflows

#### review-run

Skill-wrapper: run a review skill on a PR.

- Commands: `run <pr> [--skill ...] [--mode ...] [--label k=v]`, `list [--label k=v] --json`, `show <run> --json`.
- Uses: forgectl (pre-fetch), wtctl and `git` (throwaway checkouts, only when `run_pr_code: true`; binding A), agent-spawn, pr-comment (review-draft schema only; binding A).
- Notes:
  - Default mode headless. The session is always launched with `--kind review`, `--worktree none` and its cwd in `$CSESSION_DIR`; it never has a checkout. review-run pre-fetches the diff and metadata so the session needs no git-host credentials, and passes the review safety settings per call (section 13.1). `run --label` values pass through to the agent.
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
- Uses: pr-watch, forgectl, agent-spawn, pr-comment, `git`; optionally jobsctl (without it, runs its job command directly under an internal cap); optionally gatectl (auto-push / auto-reply decisions).
- Notes:
  - "Your PRs" are PRs authored by the user. Only comments from repo collaborators with write access or from configured reviewers trigger a respond; other comments notify only. Ignores the user's own comments by default (opt-in: `respond_to_own_comments_prefix: "/awkit"`), comments carrying the `<!-- pr-comment:v1 -->` marker on content from the user's own account, and configured bot authors. All comment text is untrusted and fenced.
  - `check` ensures that the query watch `pr-watch watch add --mine --open --owner review-respond` exists, reads events since its own cursor, keeps a per-PR comment watermark, and resolves held respond jobs.
  - Finds the agent with `agent-spawn list --label pr=<pr> --json`. If several agents match, it prefers its own respond agent (`owner=review-respond`: an earlier fork or a fresh session), then the one whose `owner` label equals config `prefer_owner` (default `ticket-work`), else the most recent. It does not enqueue while any agent working in that worktree (the original or its respond fork) is live.
  - **Forked respond sessions.** The first respond round on an agent it does not own resumes it with `--fork` (section 9.4): Claude Code forks the conversation (`claude --resume <id> --fork-session`), the fork becomes a new respond agent labeled `pr=<pr>` and `owner=review-respond` in the same worktree, and the original implement session never receives untrusted comment text. Later rounds resume the fork without `--fork`. The fork is tainted (section 8.5). Forks are torn down when the PR is merged or closed (they never own the worktree, so teardown does not remove it).
  - One job per PR (queue `respond`, `--unique-key respond:<pr>`). The job runs review-respond's internal job command, which runs `agent-spawn resume <agent_id> [--fork --label pr=<pr> --label owner=review-respond] --kind respond --prompt-file <fenced "new review comments" file> --permission-profile <bundled file> --env-allowlist-only <vars> --wait`, then records the pending confirmation and marks the delivered comment ids handled. Comments are **delivered** once the resumed session reached `working`. The prompt file contains only comments whose author passes the trigger eligibility check above; other comments are never shown to the session.
  - The respond kind profile denies `git push` and `gh`/`glab` writes (public default; section 13.1). The agent commits locally and reports an artifact `{"replies": [{"comment_id", "body"}], "commits": ["<sha>", ...]}`, which becomes a pending confirmation. `confirm <id>` requires the worktree HEAD to equal the last element of `commits` and the agent's repo config to be unchanged (`repo_config_changed` false in `agent-spawn show --json`, else exit 20, `reason: repo_config_changed`), pushes fast-forward only to the PR head ref (section 13.2 rule 10; audited), then posts the replies via pr-comment. If the remote head moved, the confirmation stays pending with `reason: remote_moved` (exit 20).
  - **Auto-push and auto-reply** (opt-in) are automatic actions: they require an enforced allowing gate (section 12.3) and these built-in hard rules: never push a diff that touches the off-limits paths (the same default list and format as review-watch's, configured in each tool), and never push unless CI on the previous PR head is green. Otherwise the pending confirmation stays for the user.
  - Fresh sessions (no original agent) only for opted-in PRs (`repos.<id>.respond_fresh: true` or a PR label), never for PRs from forks. They use `--worktree new --branch <head-ref>` and label `owner=review-respond`, and are torn down when the PR is merged or closed.
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
- `awkit cron install|uninstall`: writes crontab entries (explicit `PATH` including `~/.local/bin`, optional user-owned env-file prefix) from each adapter's `periodic:` declarations; there is no hard-coded list. The bundled adapters declare `awkit tick`, `jobsctl run`, `jobsctl reconcile`, `review-watch poll`, `pr-watch poll`, `ticket-work sync`, `ticket-queue refresh`, `review-respond check`, `agent-spawn reconcile` (which runs `claude-session reconcile` first), `memoctl prune` and `notice-route flush`, plus opt-in `ticket-work start --auto` and `agent-spawn prune`. Tools that need periodic runs also provide their own `cron install|uninstall` for standalone use; both write the same tagged crontab block per tool (`# <tool> managed`), so one replaces the other.
- **Reboot recovery:** `jobsctl reconcile`, then `agent-spawn reconcile` (which runs `claude-session reconcile`); the workflows then resume through their normal polls.
- `awkit doctor`: checks that registered tools are installed and respond, adapters load, crontab is present, required env vars are set, required binaries resolve in a non-interactive shell (with each kind's `PATH` override applied), and reports the effective kind profiles (`claude-session kinds --json`).

## 8. Claude session model (claude-session)

### 8.1 Identifiers and kinds

**Identifiers.** Three ids exist:

| Id | Owner | Notes |
|---|---|---|
| `agent_id` | agent-spawn | One per agent; maps to a `csession_id`. |
| `csession_id` | claude-session | Allocated by `start` (or by `exec` when called without `--session-id`); exported to the session as `CSESSION_ID`. |
| `claude_session_id` | Claude Code | Claude Code's own UUID, captured from the SessionStart hook payload in both modes (the headless JSON output confirms it) and updated on every SessionStart; resume always uses the latest. |

`start` allocates a `csession_id`, writes a record in state `starting`, and prints `{"csession_id": "...", "argv": [...]}`; the caller places that argv, and `exec --session-id <id>` adopts the record. Without `--session-id`, `exec` allocates one itself.

**Environment.** `exec` clears any inherited `CSESSION_ID` and `CSESSION_KIND`, then exports `CSESSION_ID`, `CSESSION_KIND` (the `--kind` value; a claimed value for consumers such as memoctl, not a verified identity) and `CSESSION_DIR` (the session's state directory; the prompt is `$CSESSION_DIR/prompt.md` and artifacts go in `$CSESSION_DIR/artifacts/`). Hooks configured on claude-session itself receive the same id as `CSESSION_ID` (the design guide's `<TOOL>_ID` convention).

**Kinds.** `--kind <name>` is a first-class flag on `exec`/`start`/`resume` (and on `agent-spawn launch/resume`), separate from labels; the launch kind is copied into a `kind=` label for display and filtering only. A **kind profile** in claude-session's config holds the permission profile, env allowlist and overrides (including `PATH`, e.g. version-manager shims), `cwd` (`session-dir` or the caller's cwd), `reads_third_party: true|false`, bounds, auto-exit and `notes_context`. Built-in kinds:

| Kind | `reads_third_party` | Default `cwd` | Used by |
|---|---|---|---|
| `implement` | false | caller's cwd (the worktree) | ticket-work |
| `respond` | true | `session-dir` (agent-spawn passes the agent's worktree) | review-respond |
| `review` | true | `session-dir` | review-run |
| `gate-check` | true | `session-dir` | gatectl |
| `rank` | false | `session-dir` | ticket-queue |
| `draft-ticket` | false | caller's cwd | ticket-create |
| `audit`, `improve` | false | caller's cwd | session-audit, self-improve (post-v1) |

A **third-party-reading kind** is one with `reads_third_party: true`; section 13 applies stricter rules to it. Unknown kinds fall back to the most conservative built-in profile (the review profile). Callers may override profile settings per call (`--permission-profile <name|file>`, `--env-allow VAR` (adds), `--env-allowlist-only VAR...` (replaces the allowlist), `--cwd`, `--timeout`, `--max-turns`). Skill-wrapper tools pass a permission profile **file** from their bundled resources and `--env-allowlist-only` on every call, so their safety never depends on another tool's config. `claude-session kinds --json` lists the effective profiles. Because behavior keys off the explicit `--kind` argument, not the caller's identity, this respects section 3.4.

### 8.2 The session wrapper (`exec`)

`claude-session exec` is the **session wrapper**: it starts `claude` as a child process, waits, records the outcome, and exits with the outcome code (section 8.3). It runs in the foreground of whatever terminal or process hosts it. Under agent-spawn, it is itself run by `agent-spawn supervise` (section 9.2).

**Flags:** `--kind`, `--skill`, `--prompt-file`, `--plugin-dir` (repeatable), `--repo <repo-id>`, `--label k=v` (repeatable), `--hook <name>=<cmd>` (repeatable, e.g. `post-state-change`), `--mode interactive|headless`, `--cwd <path>|session-dir`, `--timeout`, `--max-turns`, `--permission-profile <name|file>`, `--env-allow VAR` (repeatable), `--env-allowlist-only VAR...`, `--session-id <id>`. `resume` takes the same flags except `--session-id`, plus `--fork` and `--allow-tainted` (section 8.5).

**Bounds:** `--max-turns` applies to headless sessions only. Headless sessions have per-kind default timeouts (60 minutes; review kind 120 minutes). Interactive sessions have no timeout by default; if one is configured, `exec` enforces it as wall-clock time. Exceeding a bound ends the session with outcome `timeout` (unless a report was filed, section 8.3).

**Prompt delivery.** `exec` copies the caller's prompt file to `$CSESSION_DIR/prompt.md` and appends the standard report and escalation instructions; it **always** appends them, and callers must not add their own. Only a short, trusted bootstrap prompt goes in argv: the skill invocation plus "Read and follow `$CSESSION_DIR/prompt.md`". Headless runs feed the prompt on stdin where supported. The prompt file is readable under every permission profile. The spike (section 8.6) verifies this.

**Arguments passed to `claude`:**

- `--plugin-dir <dir>` for each `--plugin-dir` given (additive to installed plugins). Skill-wrapper tools pass their bundled `plugin/`, located via `importlib.resources`. Bundled plugins are named `<tool>` to avoid colliding with other plugins (a session plugin with the same name as an installed one would replace it for that session). Optionally, a personal marketplace can list the bundled plugins for ordinary sessions.
- `--settings <generated file>` containing the injected hooks and the kind's permission profile (merges with the setting sources in use; list values merge; managed settings still override it). Third-party-reading kinds limit `--setting-sources` (section 13.1) and run with `--strict-mcp-config` and no MCP servers.
- The bootstrap prompt (above).
- Interactive mode: `claude`; headless mode: `claude -p --output-format json`.
- Sessions on third-party code use additional isolation (section 13.2 rule 9).

**Injected hooks.** Each calls the internal `claude-session hook-event <event>`, which runs inside Claude's hook context: it only records the transition in `state.db` under a per-session lock and exits 0 with no output. The two exceptions are the headless Stop backstop and the SessionStart notes context.

- `Notification` (permission prompt) → `needs-input(permission)`; `Notification` (idle prompt) → `idle`.
- `Stop` → `idle`. Headless only: if no report has been filed in this run, block the stop once per run and ask the agent to report (backstop). Interactive sessions never block Stop.
- `UserPromptSubmit`, `PreToolUse`, `PostToolUse` → `working` (`PostToolUse` clears `needs-input(permission)` once the prompt was answered; the spike verifies this).
- `SessionEnd` → records the end reason as extra evidence.
- `SessionStart` → captures `claude_session_id`. If the kind enables `notes_context` and the start source is `startup` (by default not `resume` or `clear`), it runs the configured `notes_context_cmd` (default `memoctl context`) with the repo from `--repo` or the cwd's `origin` remote and the session's labels, and emits its fenced output as session context.

**Lifecycle hooks.** `exec`, which runs outside Claude with its own environment, watches the recorded state and fires the tool's own lifecycle hooks (e.g. `post-state-change`) only on real state changes.

**Auto-exit.** After `report done`, at the next Stop, `exec` ends the session by sending SIGTERM to the exact `claude` child PID it started (never by pattern). This closes an interactive window. The session is recorded as `exited`, with its outcome taken from the report. Configurable per kind, default on.

**Signals.**

- Interactive: `exec` ignores SIGINT (it belongs to `claude`; Ctrl-C never counts as a kill). On SIGHUP it forwards the signal to the exact child PID and ignores further SIGHUPs until its bookkeeping is done. On SIGTERM it forwards SIGTERM to the exact child and records `killed`.
- Headless: SIGINT or SIGTERM is forwarded to the exact child and `killed` is recorded.
- In both modes a filed report wins over `killed` (section 8.3).

**Liveness.** Liveness checks (by `exec`, `status`, `reconcile`) use PID plus process start time, so PID reuse is safe. `reconcile` checks both the wrapper and the recorded `claude` child.

### 8.3 Reporting and outcomes

- The session reports its status explicitly: `claude-session report done|blocked|failed|needs-input (--summary-file <path>|- | --summary "...") [--reason-file <path>|-] [--artifact <path>]`. A short `--summary` is accepted but recorded as untrusted like every summary and reason (schemas mark these fields untrusted). `--summary-file` and `--reason-file` must be `-` or resolve (after following symlinks) to a file inside `$CSESSION_DIR`, and are size-capped; other paths are rejected. `--artifact` must be inside `$CSESSION_DIR/artifacts/`; other paths are rejected.
- **Session secret.** `exec` writes a random per-session secret to a file in `$CSESSION_DIR` with mode 0600 (readable under every permission profile, like the prompt). `report` authenticates with that secret, not with `CSESSION_ID` alone, and validates that the session is live. Self-labeling (`agent-spawn label add --session`, section 9.1) uses the same secret, checked through `claude-session verify-secret <id>` (secret on stdin; exit 0 match, 11 otherwise).
- `report needs-input --reason-file ...` is the **escalation** path ("I need the user's judgment on X"). It sets state `needs-input(escalation)`.
- **Reports are per run.** A resume starts a new run and clears the current report. Within a run, the most recent report determines the outcome, and a filed report is sticky: later Stop or idle events do not clear it.
- **Precedence.** A filed report wins over `killed` and `timeout`: the outcome is the report's code, and the state records `killed` or `timeout` as the end reason.
- **Implicit done (headless):** if a headless session, after the Stop backstop has asked once, exits cleanly with a `-p` JSON result and no report, it is recorded as `reported(done, implicit)` and the JSON `result` text is saved as artifact `result.md` in `$CSESSION_DIR/artifacts/` (QRT-11). A headless abnormal exit (non-zero, or no JSON result) without a report is `exited-unreported`.
- Callers read results via `claude-session status <id> --json` (state, final report: status, summary, artifact, reason; headless cost `total_cost_usd`) or `agent-spawn show <agent_id> --json`, never via the session's stdout.

**Outcome codes.** `exec`, `resume`, `agent-spawn launch/resume --wait`, and any tool that waits on a session and passes its outcome through, exit with:

| Exit | Outcome |
|---|---|
| 0 | reported done (including implicit done) |
| 12 | the session was never started (launch phase failed) |
| 13 | the run's report is blocked or needs-input (escalation); for agent-spawn (when not promoted), the agent is parked with `needs_attention: escalated` or `blocked`, and its job, if any, becomes held (section 9.3) |
| 14 | exited-unreported |
| 15 | killed |
| 16 | timeout |
| 17 | lost |
| 18 | reported failed |

With `--json`, waiting commands also print `{"phase": "launch"|"session", "outcome": "...", "end_reason": "...", ...}`; callers branch on the JSON when they need precision.

### 8.4 States

A session is **live** in `starting`, `working`, `idle`, `needs-input` and `reported`; the other states are final until a resume.

| State | Entered when | Next states (besides the transitions common to all live states) |
|---|---|---|
| `starting` | `start` allocates, or `exec` launches `claude` (also on resume) | `working`, `idle`, `needs-input`, `reported` |
| `working` | `UserPromptSubmit`, `PreToolUse` or `PostToolUse` fires | `idle`, `needs-input`, `reported` |
| `idle` | `Stop` fires, or the idle-prompt `Notification` | `working`, `needs-input`, `reported` |
| `needs-input(permission)` | permission-prompt `Notification` | `working`, `idle`, `reported` |
| `needs-input(escalation)` | `report needs-input` | `working`, `idle`, `reported` (the escalation stays the run's report until another report replaces it) |
| `reported(done\|blocked\|failed)` | `report done\|blocked\|failed`, or implicit done | stays `reported` with an activity sub-state (e.g. `reported+idle`, `reported+working`); a later report replaces it |
| `exited` | `claude` exits after a report or an escalation was filed in this run, whatever the end reason (normal, auto-exit, killed, timeout) | `starting` (resume) |
| `exited-unreported` | `claude` exits with no report or escalation in this run | `starting` (resume) |
| `killed` | no report in this run, and the hosting terminal closed or the wrapper was signaled (e.g. a job was canceled with `--force`) | `starting` (resume) |
| `timeout` | no report in this run, and a timeout or `--max-turns` was exceeded | `starting` (resume) |
| `lost` | the wrapper is gone with no final record, or a `starting` record has had no wrapper for a grace period (found by `reconcile`) | `starting` (resume) |

Common to all live states: → `killed`, `timeout`, `lost`; on `claude` exit → `exited` if a report or escalation has been filed in this run, otherwise `exited-unreported`.

State changes fire the tool's own hooks (e.g. `post-state-change`). Standalone, claude-session only records the final state and exits with the outcome code. Policies applied around the session (window status prefix, auto-resume, promotion to interactive, parking) are owned by agent-spawn (section 9.3). `parked` is not a session state: it is a agent-spawn agent status (section 9.1).

### 8.5 Resume and forget

`resume <csession_id>` is `exec` for an existing session: it takes the same flags except `--session-id` (`--skill`, `--plugin-dir`, `--kind`, `--repo`, `--permission-profile`, `--env-allow`, `--env-allowlist-only`, `--prompt-file`, `--mode`, `--cwd`, `--timeout`, `--max-turns`, `--hook`, `--label`), plus `--fork` and `--allow-tainted` (below), and exits with the same outcome codes. It runs `claude --resume <claude_session_id>` (the latest captured id) with `--plugin-dir` and `--settings` re-passed (whether `--resume` remembers them is unverified, so always re-pass) and an optional new prompt file, and moves `exited`, `exited-unreported`, `killed`, `timeout` or `lost` to `starting`. A `--kind` given on resume applies to that run only: the stored launch kind and the `kind=` label are unchanged, and the run records its run kind. Resuming a live session, or one whose orphaned `claude` child is still alive, is refused with exit 20 (`reason: live`). (agent-spawn's `resume` accepts an `agent_id` or labels instead; section 9.4.)

**Fork.** `resume --fork` runs `claude --resume <claude_session_id> --fork-session`: the fork is a new session with its own `csession_id` (recording `forked_from`), and the original session's record and conversation are unchanged. Forking a live session is allowed (the original is not resumed). review-respond uses forks so the original implement session never receives untrusted comment text (section 5.3).

**Taint.** A session is marked `tainted` once any run of a third-party-reading kind starts on it (including a fork's first run and a fresh session launched with such a kind); a fork inherits taint from its original. Taint is never cleared and is shown in `status`/`list --json`. `resume` of a tainted session with a run kind that is not third-party-reading is refused (exit 20, `reason: tainted`) unless `--allow-tainted` is passed, which only a human gives explicitly (from a TTY, or the dashboard after its own confirmation with `--actor human:<user>`); automation never passes it.

`forget <csession_id>` drops the session record; it refuses live sessions (exit 20, `reason: live`). Transcripts and `$CSESSION_DIR` (including artifacts) are kept for a retention period, after which they are deleted; callers copy any artifact they keep long-term (review-run stores its own copy).

### 8.6 Spike (first task in the claude-session design session)

Empirically confirm:

- `--plugin-dir` is additive with user-level and project-level standalone skills;
- hooks from `--settings` merge with existing user hooks;
- behavior of `--resume` with respect to plugin dirs and settings;
- whether `--resume` keeps or changes the Claude session id, and whether `--session-id <uuid>` can pre-assign it;
- Stop-hook blocking works as described (headless);
- headless `-p` JSON output includes the session id, `result` and `total_cost_usd`, and `claude_session_id` can be captured in both modes from the SessionStart payload, including its start source (`startup`, `resume`, `clear`);
- prompt delivery: the short bootstrap prompt in argv plus `$CSESSION_DIR/prompt.md` works in both modes, and headless runs accept the prompt on stdin;
- `PostToolUse` fires after an answered permission prompt, so it can clear `needs-input(permission)`;
- clean shutdown by signaling the exact `claude` child PID after Stop (auto-exit);
- credential isolation for third-party-reading kinds (section 13.1): pointing `GH_CONFIG_DIR`/`GLAB_CONFIG_DIR` at an empty temp dir hides git-host logins without affecting Claude's own auth;
- `--setting-sources` can exclude user and project settings (and CLAUDE.md) for third-party-reading kinds, so user allow rules cannot widen their profiles; if exclusion is impossible, conservative profiles are expressed as deny rules;
- `--strict-mcp-config` with no servers leaves the session without MCP servers;
- `--fork-session` with `--resume` creates a new Claude session id, leaves the original conversation unchanged and resumable, and the fork is itself resumable by its new id;
- for the respond profile (section 13.1): `git push` and other network access are unreachable, the user's tmux server socket is unreachable, and Claude Code's sandbox (with network denied) works where available.

## 9. Agent lifecycle (agent-spawn)

### 9.1 Agents and windows

- **Agent ≠ window.** An agent is a Claude session launched by agent-spawn, identified by its `agent_id` and labels. It persists in agent-spawn state until its owning workflow (recorded as label `owner=<tool>`) says the work is finished. Windows are disposable.
- **Agent statuses:** *live* (a supervised session for the agent is live), *parked* (no live session; resumable; this includes finished headless agents), *torn down* (worktree removed, session forgotten; kept as a tombstone for N days). Selectors (`--label`) exclude tombstones; `resume` of a torn-down agent exits 10.
- **Labels:** agent-spawn is the authoritative label store for agents. It passes the agent's labels to `exec --label` and mirrors later label changes onto the session. It reads the job id from the env var named by config `job_id_env` (default `JOBSCTL_JOB_ID`) and records it as label `job=<id>`. `label add/remove <agent_id>` edits labels.
- **Self-labeling:** `label add --session <id> key=value` lets an agent label itself (e.g. `agent-spawn label add --session $CSESSION_ID pr=github.com/org/repo#42`). It is allowed only when `<id>` equals the caller's `CSESSION_ID`, the caller presents that session's secret (read from its 0600 file in `$CSESSION_DIR` and verified with `claude-session verify-secret`, section 8.3), and only for allowlisted keys (default `pr`). The secret proves access to the session's directory, not just a caller-controlled env var; in addition, third-party-reading kinds are denied `agent-spawn` by their permission profile (section 13.1).
- **Attention:** agent-spawn never creates attention items and never notifies directly. It records `needs_attention: <reason>` on the agent, where the reason is `unreported`, `escalated`, `blocked`, `failed` or `lost` (listed by `list --needs-attention`), and fires hooks: `post-escalate`, `post-park` (with a reason, e.g. `unreported`) and `post-state-change` (payload includes `agent_id`, `csession_id`, labels, state and reason). `needs_attention` is cleared by a successful resume, by teardown, or by `ack <agent_id>`. `post-state-change` is the recommended source for agent notifications and the harness.

### 9.2 Launch, hosting, waiting and jobs

- **Repo-config baseline:** when an agent gets a worktree (`--worktree new` or `<path>`), `launch` records hashes of the clone's `.git/config`, the worktree's `config.worktree` and the hooks dir (section 13.2 rule 10).
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

- **Status prefix:** `supervise` polls `claude-session status` (no extra hook process) and calls `termctl rename` to set the window's status prefix. The prefix is set on `needs-input` and on `idle` (so a brainstorming agent waiting for you is visible), and cleared on `working`. On each state change the `post-state-change` hook fires; any notification comes from what that hook is wired to.
- **Done:** auto-exit is performed by `exec` (section 8.2); `supervise` records the outcome and parks the agent.
- **Unreported exits:**
  - Headless `exited-unreported` → automatically resumed headless once with "report your status"; if still unreported → escalated (`needs_attention: unreported`, `post-escalate`), and `--wait` exits 14.
  - Interactive `exited-unreported` → parked with `needs_attention: unreported` and `post-park` (reason `unreported`); no automatic resume. The dashboard offers a one-key "resume to report". (Interactive sessions only end when the user exits them, or by auto-exit after done.)
- **Reported failed** → parked with `needs_attention: failed`; `--wait` exits 18.
- **Killed** (the window closed, or the job was canceled with `--force`) with no report → parked; no automatic resume.
- **Promotion (headless → interactive):** a per-kind setting. When enabled and tmux is available, a headless session ending blocked or needs-input is promoted: its supervisor (which remains the only supervisor) opens a window via termctl running `claude-session resume <csession_id> --mode interactive ...` with the same kind profile, and waits on the session's state; `--wait` keeps waiting until the promoted session is no longer live. When promotion is disabled or unavailable, the agent is parked with `needs_attention: escalated` (or `blocked`), `post-escalate` fires, and `--wait` exits 13.
- **Held:** a job ends held (exit 13) only when the session ends blocked or needing a human and is not promoted: promotion is unavailable or disabled, or an interactive session exits after a blocked or needs-input report. Held agent jobs are never released; the submitting workflow resolves them (`jobsctl resolve`) when it sees the outcome, and the agent continues through `agent-spawn resume` (section 5.1, jobsctl).
- **Lost** sessions (found by `reconcile`) get `needs_attention: lost`. `reconcile` also parks agents whose supervisor died.

### 9.4 Resume, attach and acknowledge

`agent-spawn resume (<agent_id> | --label k=v) [--mode headless|interactive] [--kind <k>] [--fork] [--prompt-file F] [--wait] ...` takes the same flags as `claude-session resume` (passed through) and resumes the session under supervision in the agent's original cwd (worktree). With `--fork`, the forked session (section 8.5) becomes a **new agent** in the same cwd, labeled only with the `--label` values given, recording `forked_from=<agent_id>` and the same repo-config baseline, and never owning the worktree; the original agent is unchanged. A refusal for taint (exit 20, `reason: tainted`) is passed through. The default mode is the agent's original mode; a window is opened only in interactive mode. A `--kind` given on resume applies to that run only (section 8.5). If several agents match the selector it exits 21; if the agent's session is live it exits 20 (`reason: live`), and workflows retry on their next poll; a torn-down agent exits 10.

`attach <agent_id>` focuses a live agent's window; on a parked agent it exits 10 with a hint to use `resume`.

`ack <agent_id>` clears the agent's `needs_attention` without resuming it.

### 9.5 Teardown and prune

- `teardown <agent_id> [--merged-head <sha>] [--force]` is triggered when the owning workflow declares the work complete (e.g. `ticket-work sync` sees the PR merged), by `--ephemeral` after the run, or manually.
- Teardown removes only worktrees agent-spawn created (`--worktree new`) and forgets the session. Live sessions are **always** refused (exit 20, `reason: live`), even with `--force`, and so is removing a worktree in which any agent (e.g. a respond fork) is live. If the repo-config hashes differ from the launch baseline, teardown refuses (exit 20, `reason: repo_config_changed`) before running any git command in the worktree. Teardown is itself the decision to remove, so it passes `--yes` to `wtctl remove`; a dirty or unpushed worktree is still refused (exit 20) unless a human passes `--force`, which teardown passes through; automation never does. Workflows pass the merged PR head (`--merged-head`) so squash merges do not block teardown, and retry refused teardowns on the next sync.
- Torn-down agents remain as tombstones for N days.
- `prune --older-than <age>` tears down long-parked agents. It has no default age (a no-op unless `--older-than` or config sets one) and skips agents matching config `prune.protect_labels` (label keys or `key=value` pairs; default `[owner]`) unless `--include-owned`. No label has built-in meaning; the protection comes from config.

### 9.6 Placement and nesting

- **Placement:** end state is fully configurable (naming scheme, prefix, session choice, new vs existing session, windows vs panes, max panes per window, layout, status prefix such as a bell, rulesets per repo/epic/project/kind matched via labels). v1: one new shared session, a window per agent, window named after the work (e.g. `KEY-12`, `PR#42 review`), with the status prefix of section 9.3.
- **Nesting:** review skills may themselves spawn subagents; Claude Code limits subagent nesting depth, so agent-spawn always starts top-level `claude` processes, never via the Agent tool.

## 10. Key flows

### 10.1 Review request (flow A, priority slice)

0. When jobsctl is used, `jobsctl run` runs from cron (or as a loop).
1. Cron runs `review-watch poll`.
2. forgectl lists PRs that request your review directly; draft PRs, bot-authored PRs and PRs you already reviewed yourself are skipped.
3. For each new queue item (PR, head sha, review-request instance), review-watch enqueues a jobsctl job (queue `reviews`, `--unique-key review:<pr>@<sha>`) or, without jobsctl, spawns a detached process under its internal cap, running `review-run run <pr> --mode headless --label rw-item=<id>`.
4. review-run pre-fetches diff and metadata into a fenced prompt file. If `run_pr_code: true`, it first runs the throwaway-checkout sequence of section 13.2 rule 9 and appends the fenced command output to that file. It then calls `agent-spawn launch --mode headless --kind review --cwd session-dir --skill review-run:review-pr --plugin-dir <bundled> --worktree none --prompt-file <file> --permission-profile <bundled file> --env-allowlist-only <vars> --label owner=review-run --wait` (section 13.1). The session never has a checkout.
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
3. It finds the agent with `agent-spawn list --label pr=... --json` (preferring its own respond fork, then `prefer_owner`, else the most recent) and checks that no agent in that worktree is live. It enqueues one job per PR (queue `respond`, `--unique-key respond:<pr>`; without jobsctl it runs the job command directly) whose job command runs `agent-spawn resume <agent_id> --kind respond --prompt-file <fenced "new review comments" file> --permission-profile <bundled file> --env-allowlist-only <vars> --wait`, adding `--fork --label pr=<pr> --label owner=review-respond` on the first round so the comments go to a fork, never to the original implement session (section 5.3). The prompt file holds only comments from eligible authors. The session runs in the original agent's mode and worktree, and the comments count as delivered once it reaches `working`. If no agent exists and the PR is opted in (and not from a fork), it launches a fresh respond-to-review session with `--worktree new --branch <head-ref> --label owner=review-respond`.
4. The agent commits fixes locally (it cannot push) and reports replies and commits. The job command records a pending confirmation (`post-pending`) and marks the delivered comment ids handled. You run `review-respond confirm <id>`, which checks that the worktree HEAD equals the last reported commit and that the repo config is unchanged since launch, pushes fast-forward only to the PR head ref (refusing with `remote_moved` if the remote head changed), and posts the replies via pr-comment.

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
| Respond to review comments on the user's PR | Fixes committed locally and replies drafted; the user confirms push and post | Auto-push fixes, auto-post replies behind an enforced gatectl policy, within hard rules (no off-limits paths, CI green on the previous head) |
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
- **Held jobs.** A job that exits 13 is held in jobsctl; the submitting workflow resolves it when it sees the outcome (section 9.3). Only jobs held by a `pre-start` escalation are released (`jobsctl release <id> --override-escalation`).

## 13. Security

### 13.1 Permissions and environment

- A permission profile per session kind, with a global default and per-kind and per-repo overrides, injected via `--settings` (QSC-2). Unknown kinds get the most conservative built-in profile (the review profile). Skill-wrapper tools pass the profile file and env allowlist they require on every call (`--permission-profile <file>`, `--env-allowlist-only`).
- Public defaults are conservative. The author's config uses bypass permissions everywhere.
- **Setting sources.** Third-party-reading kinds (`reads_third_party: true`: `review`, `respond`, `gate-check`) exclude user and project setting sources by default (`--setting-sources` limited), so user allow rules or a user-level bypass default cannot widen their profiles. The spike (section 8.6) verifies this; if exclusion is impossible, their profiles are expressed as deny rules.
- **Review profile** (public default for `review`, `gate-check` and unknown kinds): cwd = `$CSESSION_DIR`; Read limited to `$CSESSION_DIR`; Write allowed only under `$CSESSION_DIR/artifacts/`; Bash allowed only for `claude-session report` (so `agent-spawn` and `memoctl add` are denied); WebFetch, WebSearch and all `mcp__*` tools denied; no MCP servers (`--strict-mcp-config` with none); env allowlist; `gh`/`glab` denied, with empty `GH_CONFIG_DIR`/`GLAB_CONFIG_DIR`.
- **Respond profile** (public default) is an **allowlist**: cwd = the agent's worktree. Bash runs under Claude Code's sandbox with network access denied (preferred where available), or else is limited to `git` subcommands other than `push`, `remote`, `config` and `credential`, plus the repo's configured test and build commands; `gh`, `glab`, `agent-spawn` and `memoctl add` are therefore unavailable. Write/Edit are limited to the worktree, excluding its git dir. Read is denied for `~/.ssh`, `~/.config`, `~/.local/state`, `~/.git-credentials` and `~/.netrc`. WebFetch, WebSearch and all `mcp__*` tools are denied; no MCP servers. Environment: allowlist without git-host credentials, plus `GIT_CONFIG_GLOBAL=<empty file>` and `GIT_CONFIG_NOSYSTEM=1` (commit identity passed as `GIT_AUTHOR_*`/`GIT_COMMITTER_*`), `SSH_AUTH_SOCK` and `TMUX` unset, and `TMUX_TMPDIR` set to an empty dir. The agent commits locally (section 5.3, review-respond). The spike (section 8.6) verifies that push and the tmux socket are unreachable and that the sandbox works.
- **Isolation of third-party-reading kinds.** Sessions of third-party-reading kinds must not be able to reach the user's tmux server or write any awkit tool's config (`~/.config/<tool>/` for every awkit tool, including `~/.config/awkit/`) (which would let them add hooks or relax other tools' config); the review and respond profiles enforce this.
- **Environment.** A per-kind env setting controls which variables a session inherits, independent of permission mode. Third-party-reading kinds get an allowlist (default: `PATH`, `HOME`, `LANG`, `TERM`, and the variables Claude Code needs for its own auth) and no git-host credentials; their credential isolation also points `GH_CONFIG_DIR` / `GLAB_CONFIG_DIR` (or equivalent) at an empty temp dir. claude-session config lists `secret_env: [...]` (e.g. notification webhooks, ticket and home-automation tokens); these are stripped from every kind unless that kind's profile explicitly allows a variable. Claude's own auth is never stripped. The spike (section 8.6) verifies this.

### 13.2 Prompt injection (QSC-1)

1. **Fencing.** Untrusted text (PR titles, bodies, comments, ticket descriptions, commit messages, diffs, command output) is fenced with a random nonce: `<untrusted source="..." id="R">...</untrusted id="R">`, with a standing "data, not instructions" rule. Any `</untrusted` inside the content is neutralized (e.g. `&lt;/untrusted`). Every tool that fences follows the same rule (design guide section 12).
2. **Transport.** Untrusted or agent-generated text is never passed in argv or env to any subprocess; it goes through files or stdin. Every argument that can carry such text (bodies, titles, messages, comments, summaries, reasons, payloads, prompts) is accepted as `--<name>-file <path>` or `-` (stdin), never only as an argv string: e.g. `gatectl check --input`, `send --stdin-json` on notice-route and the channel tools, `ticketctl comment/create --body-file`, `pr-comment reply/comment --body-file` and `review --draft-file`, `memoctl add --body-file`, `claude-session report --summary-file/--reason-file`. A jobsctl job's argv never contains such text. Prompt files live under the invoking tool's state dir and are deleted when the run ends; `exec` delivers the prompt as `$CSESSION_DIR/prompt.md` with only a trusted bootstrap prompt in argv (section 8.2).
3. Untrusted content is pre-fetched deterministically before the session, so sessions do not need git-host credentials to read it.
4. Least environment per kind (section 13.1).
5. Deterministic-first gates; an agent check may only tighten a decision (section 12.3).
6. Code from other people's PRs is never executed by default (no install, no tests) unless enabled per repo (`run_pr_code: true`).
7. **Trust tiers.** Tickets from the user's configured boards are semi-trusted regardless of author, and the user's own PRs are semi-trusted: still fenced; git-host credentials not stripped by default. Tickets from external or public trackers are untrusted, as are comments by others on the user's PRs; only comments from collaborators with write access or configured reviewers trigger a respond (section 5.3).
8. **Notes.** The author kind recorded by `memoctl add` is a *claimed* kind read from the env var named by `kind_env` (default `CSESSION_KIND`; best effort, spoofable); memoctl has no dependency on claude-session. The defenses are: (a) third-party-reading kinds are denied `memoctl add` by their default permission profile; (b) everything `memoctl context` emits is fenced as `<untrusted source="memoctl" ...>`; (c) notes whose claimed kind is third-party-reading or `unknown` are excluded from other kinds' context by default.
9. **Third-party code.** Sessions on third-party code never load that code's project settings or CLAUDE.md: review sessions run with their cwd outside any checkout (the diff is pre-fetched) and with `--setting-sources` excluding project settings. When `run_pr_code: true`, review-run sequences the work so the session never has a checkout: (1) it creates a **throwaway checkout** with `wtctl create --throwaway --ref <sha>` (a separate disposable clone, not a linked worktree) and fetches the PR ref into it with its own git-host credentials; (2) it runs the per-repo configured command (e.g. tests) there deterministically, with an env allowlist (no `token_env` variables, empty `gh`/`glab` config dirs) and a timeout, and captures its output; (3) it removes the throwaway checkout; (4) it launches the review session with `--worktree none`, passing the output fenced as untrusted. `--ephemeral` is not used for this. Sandboxing the command (e.g. in a container) is an open topic (section 20).
10. **Repository-controlled config and hooks.** An agent can edit its worktree's git config, so git commands a tool runs (not an agent) on a worktree an agent used ignore repository-controlled executable config: they pass `-c core.fsmonitor= -c core.sshCommand= -c credential.helper= -c core.hooksPath=/dev/null` and run with `GIT_CONFIG_NOSYSTEM=1`. In addition, agent-spawn records hashes of the clone's `.git/config`, the worktree's `config.worktree` and the hooks dir at launch; tools refuse (exit 20, `reason: repo_config_changed`) if these changed before teardown or before a tool-performed push. Pushes use `push --no-verify` to a fully specified remote URL (never a remote name), verified to be unchanged after `insteadOf` rewriting, and an explicit ref; they are fast-forward only and never forced.

The main residual risk, acknowledged: a reviewer running with bypass permissions and live git-host credentials could be steered by a malicious PR. The env allowlist, setting-source exclusion and credential isolation mitigate it.

### 13.3 Credentials (QE-9)

Environment variables only, named in each tool's config (`token_env`; per host for forgectl). Populating the environment is the user's concern (shell profile; cron entries may source a user-owned env file). `gh`, `glab` and `claude` use their own login stores. Secrets are never logged and never appear in hook payloads, job output tails (jobsctl masks `mask_env`) or `--json` output. Hook processes inherit the tool's environment minus its configured `token_env` variables by default. Sessions lose claude-session's `secret_env` variables unless their kind allows them (section 13.1).

## 14. Audit (QSC-3)

- Every tool that takes an external action (post, approve, merge, push, transition, create) appends to `~/.local/state/<tool>/audit.jsonl`: timestamp, actor, decision id or ids (if gates were involved), target, action, input hashes (e.g. PR head SHA, config hash), result. The record format is a public contract (`schemas/audit.json`).
- Every external-action command accepts `--actor` and a repeatable `--decision-id`. The default actor is `human:<user>` when run from a TTY, otherwise `auto:unknown` unless passed; `<user>` is config `me.name`, defaulting to the OS username. Automatic callers pass e.g. `auto:<policy>` with the gate decision id, and the dashboard passes `human:<user>` for actions the user triggers.
- Agent pushes and PR creation happen inside sessions via `git`/`gh`, not through a tool (except review-respond's audited push on confirm). They are attributed by commit trailers and the PR body (added by the implement skill), recorded in the session transcript, and ticket-work `sync` writes an audit entry when it links the PR.
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
3. **Review response:** a new comment on your PR resumes a fork of the same session in a new window; it commits fixes locally and drafts replies; you confirm, and they are pushed and posted.
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
- Open topics: worktree location, branch naming, dependency bootstrap, port/container isolation, env-file copying, dangling worktree recovery, cleanup policy, auto-clone details, throwaway clone source.

### termctl

- Constraints (decided): `open` returns a stable window id; callers address windows by id, not by name. Outside tmux it targets the default server socket (configurable) and creates the session if missing.
- Open topics: naming scheme, status prefix mechanics, end-state placement config.

### claude-session

- Constraints (decided): the spike (section 8.6) runs first. `hook-event` only records state under the session lock (exceptions in section 8.2); lifecycle hooks are fired by `exec`. The `lost` grace period for orphaned `starting` records and the retention period after `forget` are configurable. The session secret file is mode 0600 in `$CSESSION_DIR`; the stored copy is compared in constant time. The size cap for `--summary-file`/`--reason-file` is configurable. Taint is recorded per session and never cleared.
- Open topics: state store, transcript access, artifact collection, Stop-hook backstop details, built-in kind profile contents, PATH/env per kind, secret file name and rotation on resume.

### jobsctl

- Constraints (decided): jobs run detached under a per-job shim that records exit status and output tail; `jobsctl run` only starts jobs up to the caps and reaps finished shims; it can run as a cron pass or as a loop. Output tails are masked per `mask_env`.
- Open topics: queue semantics details, cap configuration, output tail size.

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

- Constraints (decided): stores each agent's window id and base name (the status prefix is applied to the base name); `supervise` polls `claude-session status` for the status prefix; tmux-hosted `supervise` loads an env file from agent-spawn's state dir (mode 0600, only kind-allowed variables, never `secret_env` or `token_env` variables, deleted immediately after loading); repo-config hashes are recorded at launch and compared before teardown and on `show`; tombstones of torn-down agents are kept for N days (configurable).
- Open topics: placement config, parked cleanup, PATH/env, how secret variables a kind allows reach a tmux-hosted `supervise` without touching disk or argv, how a human clears a `repo_config_changed` refusal after inspecting the change.

### review-run

- Constraints (decided): with `run_pr_code: true`, the per-repo configured command runs deterministically in a throwaway checkout with an env allowlist and a timeout, and only its fenced output reaches the session; the session never has a checkout (section 13.2 rule 9).
- Open topics: review artifact metadata, default reviewer skill design, subagent depth limit, sandboxing the configured command (e.g. a container).

### review-watch

- Constraints (decided): queue items are keyed on (PR, head sha, review-request instance). The spend cap uses the local timezone; spend is the sum of headless `total_cost_usd`; promoted interactive time is not counted.
- Open topics: review state machine (queued → running → drafted → posting → posted → closed, plus failed), risk tier rules, rounds, staleness, shadow mode, config.

### review-respond

- Constraints (decided): a round is one successful resume or launch delivering at least one new comment (delivered = the resumed session reached `working`); the comment watermark is stored per PR in review-respond; before enqueueing it checks whether the agent is live and does not enqueue while live; comment ids are marked handled only after delivery. The respond permission profile is generated per call from the bundled allowlist profile plus the repo's configured test and build commands. The first round on a non-owned agent always uses `--fork`.
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
- **`CSESSION_DIR`:** the session's state directory, exported to the session; it holds `prompt.md` and the `artifacts/` subdirectory.
- **`CSESSION_KIND`:** the session's `--kind`, exported to the session by `exec`; memoctl records it as a claimed (spoofable) author kind.
- **Decision id:** the id gatectl returns for each decision; callers record it in their audit entries (`--decision-id`, repeatable).
- **Delivered (review-respond):** new comments count as delivered once the resumed session reached `working`.
- **Draft PR:** a pull/merge request marked as a draft on the git host.
- **Escalation:** pausing an autonomous step to ask for the user's judgment.
- **Fork (session):** a new session created by `resume --fork` (`claude --resume <id> --fork-session`) that continues a conversation without changing the original; review-respond's respond agents are forks (section 8.5).
- **Fencing:** wrapping untrusted text in nonce-tagged `<untrusted>` blocks with a "data, not instructions" rule (section 13.2).
- **Gap:** pr-watch's signal (`"gap": true`, exit 0) that a consumer's cursor is older than the retention window; the consumer re-syncs current state via forgectl and resets its cursor.
- **Gate / policy:** a gatectl decision procedure made of script and agent checks, in state `off`, `shadow` or `enforced`.
- **Hard rules:** review-watch's built-in minimum rules that no gate decision can override (section 5.3).
- **Harness:** `awkit`, the optional top-layer tool that adapts to all others.
- **Harness event:** an event `awkit` derives internally by diffing tool snapshots; never required by tools.
- **Held:** a jobsctl job paused for a human after exit 13; its slot is freed; `release` requeues it (pre-start holds only), `resolve` closes it; held is non-terminal for `--unique-key`.
- **Interface registry:** `awkit-docs/interface-registry.md`, listing each tool's version, interface spec and consumers.
- **Interface spec:** a tool's `docs/interface.md` plus its `schemas/` (section 18.1).
- **Kind:** the explicit `--kind` of a session (e.g. `review`, `implement`), selecting its kind profile.
- **Kind profile:** the per-kind settings in claude-session's config: permission profile, env allowlist and overrides, `cwd`, `reads_third_party`, bounds, auto-exit, notes context.
- **Label:** opaque `key=value` metadata stored on objects by lower tools; a multiset per object.
- **Live (agent):** an agent with a live supervised session (see agent statuses).
- **Live (session):** a session in `starting`, `working`, `idle`, `needs-input` or `reported`.
- **Managed block:** the tagged crontab block (`# <tool> managed`) that `awkit cron install` or a tool's `cron install` writes and replaces as a unit.
- **`needs_attention`:** agent-spawn's per-agent attention reason (`unreported`, `escalated`, `blocked`, `failed`, `lost`), cleared by a successful resume, teardown or `ack`.
- **`notify-tick`:** `awkit notify-tick`, a command tools' hooks call to request an early harness tick.
- **Off-limits paths:** a configurable glob list (by default covering security-sensitive code, CI and build pipeline definitions, agent configuration and instruction files, and review-ownership files) on which review-watch and review-respond never act automatically; both use the same default list and format.
- **Outcome code:** the exit code of a command that waits on a session, describing how the session ended (section 8.3).
- **Owning workflow:** the workflow tool that launched an agent, recorded as label `owner=<tool>`.
- **Parked:** see agent statuses.
- **Pending confirmation:** a recorded confirm-by-default action that was reached without a human (or escalated by a pre-hook), waiting for `confirm <id>` or `reject <id>`; announced by `post-pending` and expiring after 7 days by default (section 12.4).
- **Permission profile:** the Claude Code permission settings injected into a session via `--settings`; part of a kind profile, overridable per call with `--permission-profile`.
- **Promote:** resume a headless session that ended blocked or needing input in an interactive window, within the same job and under the same supervisor.
- **Query watch:** a pr-watch watch defined by a query (e.g. `--mine --open`) rather than a single PR.
- **Reconcile:** repair a tool's state against reality (tmux, git, processes, a host) and report what changed.
- **Repo id:** the canonical repo identifier `host/<full project path>`, used in flags, labels and config.
- **Review draft:** review-watch's stored, editable, not-yet-posted copy of a review-run artifact (pr-comment's review-draft format).
- **Risk tier:** review-watch's deterministic classification of a PR from its facts (paths, size, author, repo rules, CI); model output may only raise it.
- **Role:** a job in the tool registry (e.g. `githost`, `tickets`, `notify`) that a configured tool fills.
- **Round:** for review-watch, one review of a PR (re-reviews add rounds); for review-respond, one successful resume or launch that delivers at least one new comment.
- **Run (claude-session):** one execution of a session, from `exec` or a `resume` to exit; reports and outcomes are per run.
- **Run (review-run):** one execution of a review skill on a PR, with its stored artifact and state (`running`, `done`, `escalated`, `failed`).
- **Run loop:** `awkit run` (or the open dashboard), looping ticks with early-tick triggers.
- **Session secret:** a random per-session value `exec` writes to a 0600 file in `$CSESSION_DIR`; `report` and self-labeling authenticate with it (section 8.3).
- **Session wrapper:** `claude-session exec`, the process that runs and watches `claude`, records its state and exits with the outcome code.
- **Shadow mode:** recording what a gate would decide without enforcing it; exit 0 means "do not block", never "authorize".
- **Skill-wrapper tool:** a thin CLI that gathers context, launches a Claude session with a skill, labels it and collects the artifact (section 5.5).
- **Slice:** a set of tools that together deliver one end-to-end workflow (e.g. the review slice), used to order development (section 18.2).
- **Spike:** the empirical experiment that opens the claude-session design session (section 8.6).
- **State graph:** the harness's label-derived graph of tickets, agents, PRs, jobs and so on.
- **Status map:** per-board config mapping ticket-work events (`pr_opened`, `pr_merged`, ...) to ticket transitions.
- **Status prefix:** the marker `supervise` puts in front of an agent window's name while its session is in `needs-input` or `idle`.
- **Supervise wrapper:** `agent-spawn supervise`, which runs the session wrapper for an agent and applies post-exit policies.
- **Tainted session:** a session on which a run of a third-party-reading kind has started (or a fork of one); automation never resumes it in a kind that is not third-party-reading, and only a human may, explicitly with `--allow-tainted` (section 8.5).
- **Third-party-reading kind:** a kind with `reads_third_party: true` (built-in: `review`, `respond`, `gate-check`); it gets an env allowlist, excluded setting sources, a denial of `agent-spawn` and `memoctl add`, no access to the user's tmux server or any awkit tool's config files, and taints its session.
- **Throwaway checkout:** a disposable clone (not a linked worktree) at a PR's head sha, created by review-run through `wtctl create --throwaway` only when `run_pr_code: true`, used to run a configured command deterministically and removed before the review session starts; the session never has a checkout.
- **Tick:** one harness iteration of poll → diff → derive events → update graph → rules.
- **Tool registry:** the `roles` map in awkit's config naming which tool fills each role.
- **Torn down:** see agent statuses.
- **Unique key:** a jobsctl `--unique-key`; adding a job whose key matches a non-terminal (including held) job is a no-op that returns the existing id.
