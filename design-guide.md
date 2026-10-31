# awkit Tool Design Guide

Status: v1.10, 2026-10-31. v1.10: jobsctl design session: a tool may signal the process group it created for a job it runs, not only for a hook (§8, §12); a tool with no repo notion (jobsctl) scopes settings by its own unit instead of `repos:` (§5). v1.9: the hardened git rule points to the verified invocation in architecture section 13.2 rule 10, and the repo-config baseline is wtctl's (§12); wtctl review pass 1: teardown refuses on the baseline's `git` class, a push on either class (§12). v1.6: renamed cw → awkit; tools unprefixed. v1.7: versioning and releases (§13), CI and markdown lint (§14), layout additions (§15), contributing workflow (§17). v1.8: skill-wrapper tools expose a config key replacing their bundled permission profile; standard instructions reach the session through the system prompt (§11); claude-session review pass 1: wrappers also pass `--sandbox` and `--setting-sources` per call, each replaceable in their own config (§11). Review passes 2 and 3: a `decision_id` from a step that is not an external action is recorded in state and log (§8); the repo-config baseline adds included config files, the `core.hooksPath` dir and submodule configs and hooks, and the hardened git flags add `diff.external`, `core.pager`, `--no-ext-diff` and `--no-textconv` (§12). Review pass 4: the session outcome table matches architecture section 8.3 (§4.2); skill wrappers pass `--repo` explicitly (§11); a tool that commits on an agent's behalf uses the hardened flags and the user's identity (§12). Destined for the `awkit-docs` repo. See `architecture.md` for the system design.

This guide describes the conventions every awkit tool follows. It is **a document, not a library**: nothing here is imported, and no tool is required to comply for another tool or the harness to work with it (adapters bridge any gaps). Following it makes a tool predictable for humans and trivial to adapt.

Key words: **must** = our tools always do this; **should** = do this unless the tool's design doc explains why not; **may** = optional.

---

## 1. Identity and independence

- A tool **must** be useful on its own at a terminal.
- A tool **must not** depend on the harness (`awkit`), a bus, a shared library or a shared contracts package.
- A tool **may** depend on other awkit tools in a lower layer or the same layer, and on third-party CLIs, provided the dependency graph stays acyclic. Layers are a guide to direction; the hard rules are no upward awareness and no cycles.
- A tool **must not** know about, or behave differently for, any tool that calls it. Behavior **may** differ by explicit arguments (e.g. `--kind`), never by caller identity.
- A tool that is meant to be shared **must not** require user-only pieces (tmux, personal notifiers) for its core function.
- A tool's repo, Python distribution, executable, config dir, state dir and bundled plugin **must** all use the tool's name. Its Python package is the name with dashes → underscores.
- Tool names **must** follow these naming rules:
  1. Primitives that manage a resource: `<resource>ctl` (forgectl, ticketctl, wtctl, termctl, gatectl, jobsctl, memoctl).
  2. Tools bound to a vendor or channel: `<vendor-or-channel>-<role>` (claude-session; slack-notice, ha-notice, desktop-notice). A future vendor session tool would be e.g. `codex-session`.
  3. Workflow/composite tools: `<family>-<verb>`, always hyphenated (pr-watch, pr-comment, review-run, review-watch, review-respond, ticket-queue, ticket-create, ticket-work, notice-route, agent-spawn, session-audit, self-improve).
  4. The harness is `awkit`; the docs repo is `awkit-docs`. There is no shared tool prefix: tools do not belong to the harness. New names **must** be checked free on PyPI, Homebrew, apt and common PATHs.
- A tool **must not** contain organization-specific values (company names, ticket project keys, custom-field IDs, hostnames, repo or org names). Those belong in the user's config. Repos are public.

## 2. Dependencies between tools

Every dependency on another tool **must** be declared in the README with its binding type:

| Type | Use when | How |
|---|---|---|
| A, hard | The pair is tightly coupled | Call by name, parse its documented `--json` output. |
| B, configurable command | Alternatives share inputs/outputs | Config key such as `githost_cmd: forgectl`, defaulting to ours. |
| C, adapter | Alternatives differ | An adapter module/file per alternative maps it into this tool's model. |

- When calling another tool, a tool **must** use its `--json` output and its documented exit codes.
- A tool **must not** read another tool's `state.db`; it is private.
- A tool's `audit.jsonl` and `log.jsonl` are public, append-only contracts (section 6). Other tools **may** read and watch them. A harness adapter **may** watch them purely as a trigger for an early poll; data is still read via the CLI.

## 3. Language and stack

Default (non-Python tools **must** document an equivalent and install with one command):

- Python ≥ 3.12, managed with `uv`; installed with `uv tool install git+https://github.com/agent-workflow-kit/<repo>`.
- CLI: stdlib `argparse` with subcommands.
- Config: YAML via `pyyaml` (required: the stdlib cannot read YAML), validated with Pydantic.
- State: stdlib `sqlite3` in WAL mode.
- TUI (only if the tool ships one): Textual.
- Quality: pytest, ruff (lint + format), pyright.
- **Minimize dependencies.** Each dependency **must** be justified in the design doc.

## 4. CLI conventions

### 4.1 Commands, arguments and output

- Commands **must** use the subcommand style `<tool> <verb> [args]`.
- Every command that outputs data **must** support `--json`. Human-readable output is the default and **may** change freely; `--json` output is a versioned contract described in `schemas/`.
- A tool **should** support these global flags wherever they are meaningful: `--json`, `--config PATH`, `--verbose`, `--quiet`, `--dry-run`, `--yes` (skip confirmation; see section 4.4).
- Errors **must** go to stderr. With `--json`, errors **must** also be emitted as `{"error": {"code": "...", "message": "..."}}` on stdout.
- Commands that change external state **should** be idempotent and **must** support `--dry-run`.
- Commands that take an external action **must** accept `--actor` and a repeatable `--decision-id` for audit (section 6).
- Every tool **must** support `--version`.
- **Untrusted or agent-generated text.** Any argument that can carry untrusted or agent-generated text (bodies, titles, messages, comments, summaries, reasons, payloads, prompts) **must** be accepted as `--<name>-file <path>` or `-` (stdin), and **must not** be accepted only as an argv string. A short argv form (e.g. `--summary "..."`) **may** exist for convenience, but its value **must** be treated as untrusted like the file form. A command that builds argv for another process (e.g. a jobsctl job) **must not** put such text in it. Examples: `gatectl check <policy> [--input <file>|-]`; `send --stdin-json` on notice-route and the channel tools (plain `--title`/`--message` remain for trusted human use); `ticketctl comment/create --body-file`; `pr-comment reply/comment --body-file` and `review --draft-file`; `memoctl add --body-file|-`; `claude-session report --summary-file/--reason-file`.
- **Identifiers.** A repo **must** be identified as `host/<full project path>` in flags, labels and config. A PR **must** be accepted as a URL or as `host/<full project path>#N` (GitLab MR numbers written without `!`), and `--json` output **must** use the `#N` form.

### 4.2 Exit codes

Exit codes are reserved across all tools and **must** be used with these meanings:

| Code | Meaning |
|---|---|
| 0 | success |
| 1 | unexpected or internal error |
| 2 | usage error (including: no `--input` and stdin is a TTY) |
| 10 | not found |
| 11 | vetoed / denied (a pre-hook or policy denied) |
| 12 | the requested operation failed for an expected, reportable reason (for launch/resume: the session was never started) |
| 13 | needs a human: escalated, held, or pending confirmation recorded (or, for a tool without a pending store, left for the caller to record) |
| 14–19 | session outcomes (passed through by any tool that waits on a session) |
| 20 | refused (e.g. target busy or live, dirty or unpushed worktree, stale head) |
| 21 | ambiguous selector (several objects match) |
| 22+ | tool-specific, documented in the README and schemas |

A refusal (exit 20) **must** carry a machine-readable `reason` in its JSON output. Shared reason strings: `live`, `dirty`, `unpushed`, `stale_head`, `remote_moved`, `repo_config_changed`, `tainted`; tools **may** add others and **must** document them.

Session outcomes, used by `claude-session exec`/`resume`, `agent-spawn launch/resume --wait`, and any tool that waits on a session and passes the outcome through (architecture section 8.3):

| Code | Outcome |
|---|---|
| 0 | done (reported, or implicit for a clean headless exit) |
| 11 | a pre-launch hook vetoed the launch (phase launch; the session never started) |
| 12 | the session was never started (launch phase failed) |
| 13 | reported blocked or needs-input (escalation), or a `pre-launch` hook escalated the launch |
| 14 | exited-unreported |
| 15 | killed |
| 16 | timeout |
| 17 | lost |
| 18 | reported failed |

Reports are per run, and the run's most recent report determines the outcome; a filed report wins over `killed`, `timeout` and `lost`. With `--json`, waiting commands **must** also print `{"phase": "launch"|"session", "outcome": "...", "end_reason": "...", ...}`; callers **should** branch on the JSON when they need precision.

### 4.3 Concurrency and periodic runs

- Commands invoked by cron or the harness **must** be safe under concurrent invocation: take a per-object lock in `state.db`; a second caller exits 0 reporting "already running".
- Per-object locks **must** be leases (holder PID + process start time + expiry); a lock whose holder is dead **may** be taken over.
- Tools that need periodic runs **should** provide `cron install|uninstall`, writing entries with an explicit `PATH` (including `~/.local/bin`) and an optional user-owned env-file prefix, inside a tagged managed crontab block (`# <tool> managed`) so that the harness's `awkit cron install` and the tool's own command replace each other's block.

### 4.4 Confirmations, holds and `--yes`

- **Pending store.** A tool that has confirm-by-default actions and runs them on behalf of automation **should** keep a pending store and then **must** support `pending`, `confirm <id>` and `reject <id>`. It **may** offer aliases (e.g. `approve` for `confirm`).
- **Without a human.** When a confirm-by-default action is reached without a human (non-TTY) and without `--yes`, or a pre-hook escalates (exit 13), the tool **must not** proceed:
  - a tool with a pending store records a pending confirmation, fires its `post-pending` hook, and exits 13;
  - a tool without a pending store (e.g. ticketctl, forgectl `merge`, pr-comment, wtctl `remove`) exits 13 and leaves recording to its caller.
- **Pending confirmation records** **must** include at least `id`, `tool`, `action`, `target`, `created`, `summary` and `expires`. The default expiry **should** be 7 days.
- **`confirm <id>`** **must** re-check the action's preconditions and re-run the other pre-hooks, overriding only the escalating hook's verdict, before performing the step. `reject <id>` drops it.
- **Commands that require a human** (e.g. ticket-create `create`) **must** exit 13 when there is no TTY.
- **`--yes`.** Automation (cron entries, harness rules, jobs) **must never** pass `--yes` to bypass a confirm default. A caller **may** pass `--yes` to a lower tool only to execute an action already accepted by a human, explicitly enabled by config, or allowed by an enforced gate (section 12). A caller's own documented policy (e.g. teardown removing a worktree) **may** justify `--yes` only for local, non-publishing actions that remain subject to safety refusals; it **must never** justify post, approve, merge, push, ticket transition or ticket creation, which require a human acceptance, a config opt-in, or an enforced allowing gate. Relaxing a confirm default **must** be done in config (e.g. `auto_transition: true`). A TUI that confirms in its own dialog (e.g. the harness dashboard) passes `--yes --actor human:<user>`.
- `--yes` **must never** override a refusal (exit 20); only a human `--force` **may** override the `dirty` and `unpushed` refusals, and nothing overrides `live`.

## 5. Configuration

- Location: config **must** live at `~/.config/<tool>/config.yaml` (respecting `XDG_CONFIG_HOME`; the same path on macOS). `--config` overrides the path.
- Drop-ins: a tool **must** also read `~/.config/<tool>/config.d/*.yaml` in lexical order, merged after `config.yaml` (maps are merged; hook lists are appended). Other programs (e.g. `awkit wire`, which writes `config.d/awkit.yaml`) **must** write drop-in files and **must not** edit `config.yaml`.
- Environment variables: a tool **may** accept config values from env vars named `<TOOL>_<KEY>` (`<TOOL>` is the tool name upper-cased, dashes → underscores, e.g. `FORGECTL_TOKEN`; nested keys joined with `__`). A tool **may** declare a different env prefix in its interface when its derived prefix would collide with another tool's or program's namespace; it then uses that prefix for all its env vars, including hook variables. Example: claude-session uses `CSESSION_` (not `CLAUDE_SESSION_`, which would sit in Claude Code's `CLAUDE_*` namespace). Names a tool documents for other purposes (e.g. its hook variables, section 8) are not config keys.
- Precedence **must** be: CLI flags > per-repo override > environment variables > global config (including drop-ins) > built-in defaults. Per-repo overrides outrank env on purpose, so a global env setting cannot silently override a repo's safety settings.
- Per-repo overrides **must** live under a `repos:` map keyed by repo id (`host/<full project path>`). The current repo is `--repo`, else the input object's repo, else the cwd's `origin` remote. A tool that has no notion of a repository (jobsctl, whose jobs are argv arrays) **may** omit `repos:` and never derive a repo; it documents the unit that scopes its settings instead (jobsctl: the queue, which takes the per-repo position in the precedence order).
- The repo **must** ship `config.example.yaml` documenting every key with its default.
- Built-in defaults **must** be the safe public defaults (architecture section 12.1 and this guide section 12).
- Invalid config **must** fail fast with a message naming the key and the problem.
- A tool that needs to know "me" **should** read `me: {name: ..., github: ..., gitlab: ..., jira: ...}` from its config, falling back to the CLI's logged-in user. `me.name` defaults to the OS username.

## 6. State, logs and audit

- State dir: state **must** live under `~/.local/state/<tool>/` (respecting `XDG_STATE_HOME`; the same path on macOS).
- Database: `state.db` (SQLite, WAL) is private to the tool. Its schema **must** be versioned with migrations.
- Log: `log.jsonl` (structured JSON lines) **should** be written; it is a public, append-only contract described by `schemas/log.json`.
- Audit: `audit.jsonl` **must** be appended for every external action (e.g. post, approve, merge, push, transition, create). It is a public contract described by `schemas/audit.json`. Fields: `ts`, `actor`, `decision_id` (if gates were involved; may be a list), `target`, `action`, `inputs` (hashes, e.g. head SHA, config hash), `result`.
- The `actor` comes from `--actor`; the default **must** be `human:<user>` when run from a TTY, otherwise `auto:unknown`, where `<user>` is `me.name`. Automatic callers **should** pass e.g. `auto:<policy>` and `--decision-id`; the harness dashboard passes `human:<user>` for actions the user triggers.
- Actions taken inside Claude sessions with `git`/`gh` (e.g. an agent pushing a branch) are not tool actions; they are attributed by commit trailers and PR bodies, and the workflow tool that later links them **should** write an audit entry.
- An `export` subcommand **should** exist for tools with an audit log.
- A `reconcile` subcommand **should** exist for tools whose state mirrors something external (tmux, git, processes, a host); it repairs state against reality and reports what it changed.
- Secrets **must never** be stored in state, logs, audit or output.

## 7. Credentials

- A tool **must** read credentials only from environment variables. The variable name **should** be configurable (`token_env: MY_TOKEN`); a tool that talks to several hosts **should** make it configurable per host.
- A tool **should** rely on `gh`, `glab` and `claude` for their own logins; it **may** pass a per-call token from a configured env var (e.g. `GH_TOKEN` for each `gh` call).
- Required env vars **must** be documented in the README; a missing one **must** fail with a clear message naming the variable.
- A tool that captures output from subprocesses **should** mask the values of configured secret variables (e.g. `mask_env`) before storing or printing it.

## 8. Hooks

- A tool **should** expose `pre-<step>` and `post-<step>` hooks at each meaningful step. The tool chooses its steps and documents them.
- A tool that detects external changes (e.g. pr-watch) **should** expose `on-<event>` hooks (e.g. `on-comment`, `on-approved`, `on-merged`). They report a change that already happened and cannot veto.
- A tool with a pending store **must** fire `post-pending` when it records a pending confirmation.
- Configuration: hooks **must** be configured in the tool's own config (including drop-ins), for example:

  ```yaml
  hooks:
    pre-enqueue:
      - cmd: "gatectl check start-work --timeout 540"
        timeout: 600          # gate policies with agent checks need long timeouts
    post-status:
      - cmd: "notice-route send --source ticket-work --stdin-json"
        async: true
  ```

- A tool **may** also accept per-invocation hooks via `--hook <name>=<cmd>` (repeatable), run in addition to configured hooks.
- Execution: `cmd` **must** run via `sh -c`, in its own process group, which the tool creates and records. There is **no** `{...}` template substitution.
- Input: a hook **must** receive a JSON document on stdin describing the step in the tool's own terms (documented in `schemas/hooks/<hook>.json`). Payloads **should** include top-level `tool`, `hook`, `object_type`, `object_id`, `repo` (repo id) and `labels` where applicable, so policies (e.g. gatectl) can match on them.
- Environment: a hook **must** receive `<TOOL>_HOOK=<hook name>`, `<TOOL>_ID=<object id>` and `<TOOL>_OBJECT_TYPE=<object type>`, where `<TOOL>` is the full tool name upper-cased with dashes → underscores (e.g. `JOBSCTL_HOOK`), or the tool's declared env prefix (section 5; e.g. claude-session's `CSESSION_HOOK`, `CSESSION_ID`, `CSESSION_OBJECT_TYPE`). Data comes only from stdin and these documented env vars; untrusted text **must never** be placed in env vars or on the command line.
- Hook processes **must** inherit the tool's environment minus the tool's configured `token_env` variables by default.
- Outcome of `pre-` hooks, run in order:
  - exit 0: continue;
  - exit 13: **escalate**: the remaining hooks still run; if none vetoes, the step is held (not vetoed) and the tool proceeds as in section 4.4, exiting 13;
  - any other non-zero exit: **veto**: the step is aborted immediately (later hooks do not run), the hook's stderr is reported as the reason, and the tool exits 11.
- Hook stdout **may** be a JSON object; if it contains `decision_id`, the tool **must** record it in its audit entry for the step, or, for a step that is not an external action (e.g. a session launch), in its state and log. All returned decision ids **must** be recorded (`decision_id` may be a list).
- `post-` and `on-` hooks cannot undo anything. Their failures **must** be logged and warned, never fatal.
- Timeouts: each hook **must** have a timeout (default 30 seconds, configurable per hook). On timeout the tool **must** signal the hook's process group (group signals are allowed only for groups the tool created, section 12). A pre-hook timeout counts as a veto; a hook that can take long (e.g. `gatectl check`) **should** be given its own shorter timeout (`--timeout`) so it escalates instead. `async: true` (post- and on- hooks only) runs the hook detached.

## 9. Labels

Tools that create long-lived objects (jobs, agents, worktrees, sessions, notes, watched PRs) **should**:

- accept repeated `--label key=value` on creation (and `label add/remove` later);
- store labels as a multiset of `key=value` pairs: adding an identical pair is a no-op; `label remove key=value` removes that pair; a key **may** carry several values;
- return them verbatim in `--json` output;
- filter on them: `list --label key=value` (repeatable, AND across flags; a flag matches if the object has that pair among any values of the key).

A tool **must not** assign built-in meaning to any label key; user config **may** match rules on labels. Conventional keys used by higher tools: `ticket`, `pr` (`host/<full project path>#N` for both GitHub and GitLab, with the GitLab MR number written without `!`; e.g. `pr=github.com/org/repo#42`), `repo` (`host/<full project path>`), `kind`, `owner` (the owning workflow tool), `job` (a jobsctl job id), `epic`, `project`.

## 10. TUIs

- TUIs are optional. A tool that ships one **must** expose it as `<tool> browse`.
- It **should** support `--focus <id>` to open on a specific item.
- It **should** support `--result-file PATH`: on exit, write `{"intent": "<tool-defined>", "selected": [...]}` in the tool's own vocabulary (chooser-file pattern). Without the flag, it **must** write nothing. Without `--result-file`, a `browse` picker still works standalone and in scripts.
- It **must** run correctly when launched as a foreground child of another TUI (no assumptions about being the only app).
- Every TUI action **must** also be available as a CLI command.
- Keybindings **should** be: `q` quit, `?` help, `/` filter, `enter` open, `r` refresh.
- Style (minimal; to be extended in the `awkit` session). A TUI **should** have:
  - a header showing the tool name;
  - a footer with key hints;
  - a status/notification line;
  - explicit empty and error states.

  It **must** respect the terminal's colors and **must not** hard-code backgrounds.

## 11. Skill-wrapper tools

Tools that run a Claude skill **should** follow this pattern:

1. Gather context deterministically (no model) and write it, fenced, to a prompt file (section 12).
2. Launch the session with the skill, the prompt file, an explicit `--kind`, an explicit `--repo <repo-id>` when the work concerns a repository (claude-session never derives it for kinds whose cwd is the session directory), labels, the bundled `plugin/` via `--plugin-dir`, and the safety settings the tool requires passed per call: a permission profile **file** from the tool's bundled resources (`--permission-profile <file>`), `--sandbox required`, `--setting-sources ""` and `--env-allowlist-only VAR` (repeatable; it replaces the allowlist rather than adding to it), so its safety never depends on another tool's config. Tools that need tmux windows, worktrees or resume use `agent-spawn`; tools that only need a headless run (e.g. gatectl agent checks, ticket-queue re-rank) **may** call `claude-session exec` directly.
3. Do **not** add report or escalation instructions: `claude-session exec` always passes the standard instructions through the system prompt (report via `claude-session report ...`; escalating with `needs-input` is always acceptable), and wrappers **must not** add their own. `exec` copies the prompt into the session directory and delivers it as a file, with only a short bootstrap prompt in argv.
4. Collect the result via `status --json` / `show --json` and the artifact named in the report, validating the artifact against the slot contract. A tool that keeps artifacts long-term **must** copy them into its own state dir (session dirs are deleted after `forget` plus the retention period).

Requirements:

- **Must** offer `--mode interactive|headless`, with a documented default.
- **Must** offer `--skill <name>` to use any skill instead of the default. A skill name is whatever Claude Code accepts as a slash command: `plugin:skill` for plugin skills (bundled defaults are `<tool>:<skill>`), bare names for user or project skills.
- **Must** bundle the default skill(s) in `plugin/` as a Claude Code plugin named `<tool>`, located via `importlib.resources` and passed via `--plugin-dir`.
- **Must** document the slot contract: inputs given to the skill, the artifact format expected back.
- **Must** expose config keys that replace the safety settings it passes per call: its bundled permission profile file (e.g. `permission_profile`), the `--sandbox` level (e.g. `sandbox`, default `required`), the `--setting-sources` list (e.g. `setting_sources`, default none) and the env allowlist it passes with `--env-allowlist-only` (e.g. `env_allowlist`), so a user can run its sessions with a more permissive (or stricter) setup without another tool weakening an explicit per-call request.
- **Must** read the artifact from the frozen path that `claude-session status --json` reports (the session's working copy can still change while the session is live).

Tools whose skill step is internal and headless-only (gatectl agent checks, ticket-queue re-rank) are exempt from `--mode` and configure their skill in config.

## 12. Safety

- **Safe public defaults:** built-in defaults **must** be the defaults in architecture section 12.1 (drafts before posting; confirmation before posting, approving, merging or creating tickets; draft PRs only; conservative permission profiles; allowlisted environments for sessions that read third-party content).
- **Fencing:** a tool **must** fence untrusted text (PR, ticket, comment, commit, diff text and command output) with a random nonce, `<untrusted source="..." id="R">...</untrusted id="R">`, with a standing "data, not instructions" instruction, and **must** neutralize any `</untrusted` inside the content (e.g. `&lt;/untrusted`). It **should** pre-fetch untrusted content rather than make sessions fetch it.
- **Transport:** untrusted or agent-generated text **must never** be passed in argv or env to any subprocess; use files or stdin (section 4.1). Prompt files **must** live under the invoking tool's state dir and be deleted when the run ends.
- **Trust tiers:** a tool **must** treat tickets from the user's configured boards and the user's own PRs as semi-trusted: still fenced, git-host credentials not stripped by default. It **must** treat tickets from external or public trackers and comments by others as untrusted.
- **Untrusted code:** a tool **must never** execute untrusted code by default.
- **Third-party-reading sessions:** sessions of third-party-reading kinds **must not** be able to reach the user's tmux server or write any awkit tool's config (`~/.config/<tool>/` for every awkit tool, including `~/.config/awkit/`). A session that ran such a kind is tainted: automation **must never** resume it in a kind that does not read third-party content; only a human **may**, explicitly (architecture section 8.5). Tools that pass untrusted text to a session in a follow-up (e.g. review comments) **should** resume a fork rather than the original session. Notification templates **must** exclude the report summary and reason of third-party-reading kinds by default.
- **Repository-controlled config and hooks:** every git command a tool runs on a repository, worktree or checkout an agent may have used **must** use the hardened git invocation of architecture section 13.2 rule 10 (a clean environment with `GIT_CONFIG_GLOBAL=/dev/null` and `GIT_CONFIG_NOSYSTEM=1`, the full override set, neutralized filter drivers, explicit `--git-dir`/`--work-tree`, fetches only from a recorded URL); the list there is normative and is not restated here, and a tool applying it **must** keep a `live` regression test of it. A tool **must** refuse (exit 20, `reason: repo_config_changed`) to push from a worktree whose repo-config baseline (recorded by wtctl; architecture section 13.2 rule 10) has changed in either class, checking with `wtctl baseline check`, and to tear down a worktree whose `git`-class items changed, which `wtctl remove` checks. A tool that commits an agent's changes on the user's behalf (review-respond's confirm) **must** run the commit outside the session's sandbox with the hardened invocation and the user's own git identity, staging exactly the files it verified. Pushes **must** use `push --no-verify` to a fully specified remote URL (never a remote name), verified after `insteadOf` rewriting, and an explicit ref; they **must** be fast-forward only and **must never** be forced.
- **Gates:** script checks **must** run before agent checks; an agent check **may** only tighten a decision. A gate's exit 0 in shadow mode means "do not block", never "authorize": a caller that uses a gate to enable an automatic action (auto-post, auto-approve, auto-merge, auto-push, auto-reply) **must** require `"enforced": true` and `"decision": "allow"` in the gate's JSON, and otherwise fall back to the manual default. Its built-in hard rules still apply: automatic actions **must never** touch the configured off-limits paths, and an automatic push **must** require green CI on the previous head. An automatic merge **must** pass the head the gate evaluated (`forgectl merge --expected-head <sha>`).
- **Escalation:** any autonomous step **must** have a path to ask the user.
- **Attribution:** artifacts posted on the user's behalf **should** carry a configurable footer/trailer, and **must** carry one for automatic actions. Every footer template **must** include the fixed marker `<!-- pr-comment:v1 -->`, and detection of awkit-authored content **must** match the marker only on content authored by the user's own account.
- **Channel output:** notification tools **must** escape platform markup in title and message (no mentions, no link injection); links are added only via the `link` field or `--link`.
- **Never destroy work:** a tool **must never** run `git reset/checkout/clean/restore` on user files. It **must** always refuse to tear down live sessions (exit 20, even with `--force`), and **must** refuse to remove dirty or unpushed worktrees unless a human passes `--force`; automation **must never** pass `--force`. It **must never** kill processes by pattern: it signals only an exact PID it started, verified by PID plus process start time, or a process group it created and recorded for a hook or for a job it runs (e.g. jobsctl's shim, after signaling the job's exact PID first).

## 13. Schemas and versioning

- `schemas/` **must** contain JSON Schema (draft 2020-12) for every `--json` output (`schemas/cli/<command>.json`; nested command names join with `-`, e.g. `schemas/cli/label-add.json`) and hook payload (`schemas/hooks/<hook>.json`), plus `schemas/config.json`, `schemas/audit.json` and `schemas/log.json`. Fields that carry untrusted or agent-generated text (e.g. a report's summary and reason) **must** be marked untrusted in the schema.
- Tests **must** validate real output against these schemas.
- A dependent tool **may** copy a sibling's schema files into its tests (pinned to a version); it **must not** import them.
- Each tool **must** use semver, released automatically from Conventional Commit PR titles by python-semantic-release (architecture section 18.3): `feat` → minor; `fix`, `perf`, `chore`, `refactor`, `build` → patch; `docs`, `test`, `ci`, `style` → no release; `!` → major (minor while on 0.x).
- Tools **must** stay on 0.x until usable and stable, and **must not** use `!` before then. A breaking change to the CLI, `--json` output, hook payloads or config schema **must**, before 1.0, be a `feat` commit whose title names the break (it becomes the changelog line; details go in the PR body), and from 1.0 on a `!` commit; either way it **must** come with an update to `awkit-docs/interface-registry.md`.
- `CHANGELOG.md` and the version in `pyproject.toml` **must** only be changed by the release job (except the initial scaffold).

## 14. Testing

- All subprocess and HTTP calls **must** go through one gateway module (e.g. `src/<package>/gateway.py`) so tests can substitute fakes.
- `--json` output **should** have golden-file tests.
- Fake binaries for external CLIs **should** live in `tests/fakebin/` and **must** be copied per repo, never shared.
- `make verify` runs ruff (lint and format check), pyright, pytest and markdown lint (`pymarkdownlnt`); it **must** pass before every commit, and CI **must** run the same target.
- Real-world tests (real hosts, real `claude`) **must** be marked `live`, **must** be deselected by default, and **must never** run in CI. CI never holds model or host credentials.
- CI runs on Linux only (Python 3.12 and 3.13); macOS compatibility is checked locally.

## 15. Repo layout

Every repo **should** follow this layout:

```text
<tool>/
  README.md            purpose, layer, commands, dependencies (with binding types and
                       install commands), env vars, exit codes
  CLAUDE.md            instructions for Claude sessions working on this repo
  CHANGELOG.md
  LICENSE              MIT
  pyproject.toml
  Makefile             verify, test, lint, fmt
  config.example.yaml
  docs/interface.md    interface spec: commands, flags, exit codes and refusal reasons,
                       hooks, config shape, slot contract (written first)
  docs/design.md       tool design doc (starts from the architecture's constraints and open topics)
  docs/plan.md         implementation plan and version roadmap (written in the planning stage)
  schemas/             cli/, hooks/, config.json, audit.json, log.json
  .github/             caller workflows (from awkit-ci), dependabot.yml, PR template
  src/<package>/       package (dashes → underscores)
  tests/               unit tests, golden files, fakebin/
  plugin/              (tools that bundle skills) .claude-plugin/plugin.json, skills/
```

Every repo **must** be licensed MIT, "Copyright (c) 2026 agent-workflow-kit contributors".

## 16. Documentation

- The README **must** be the user-facing contract: install, quick start, commands, config, hooks, exit codes, env vars, and required sibling tools with their install commands. A missing sibling **must** produce a clear error naming its install command.
- `docs/interface.md` **must** be written before implementation and kept current (architecture section 18.1).
- `docs/design.md` **should** record the tool's decisions and remaining questions.
- A session that changes the interface **must** keep the interface registry in `awkit-docs` current.

## 17. Contributing workflow

- Work **must** happen on a branch in a git worktree, never in the main checkout. Branch names **should** be `<type>/<short-slug>`.
- Every change **must** reach `main` through a PR; the PR title **must** be a Conventional Commit header (it becomes the squash commit, the version bump and the changelog line). Merges are squash-only.
- Agent sessions **must not** merge a PR without the maintainer's explicit instruction for that PR; merging goes through `awkit-ci`'s `scripts/pr-merge`, which waits for all checks.
- Where the maintainer's local private-content guard is installed, its hooks **must not** be bypassed (`--no-verify` is forbidden), and PR titles, bodies and comments **must** be checked with `guard text` before they are posted (architecture section 18.7).
