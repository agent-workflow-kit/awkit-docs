# Roadmap

Derived from `architecture.md` (v1.20), sections 8.6, 18.2 and 19. If this file and the architecture disagree, the architecture wins; update this file.

## Build order

1. Interface design for all L1 tools, in parallel.
2. Interface design for L2, then L3, then `awkit` (each can start once the interfaces it depends on exist).
3. Implementation proceeds in parallel as soon as the interfaces a tool depends on are committed.

Priority: the **review slice** first, the **ticket slice** in parallel. The shared base (`claude-session`, `termctl`, `wtctl`, `agent-spawn`) is the critical path for both.

## Slices

| Slice | Tools (dependency order) |
|---|---|
| Base | claude-session, termctl, wtctl → agent-spawn; jobsctl |
| Review | forgectl → pr-comment → review-run → review-watch; then gatectl, pr-watch |
| Tickets | ticketctl → ticket-queue → ticket-work (needs base + forgectl) |
| Notify | slack-notice, ha-notice, wsl-notice → notice-route |
| Response | review-respond (needs base + forgectl + pr-comment + wtctl) |
| Support | memoctl, ticket-create |
| Harness | awkit |
| Post-v1 | session-audit, self-improve |

## v1 is done when (on the author's WSL machine)

1. **Review slice:** review-watch (cron) picks up a review request, runs review-run headless with the configured skill, drafts, and notifies via Slack/Home Assistant; one-key accept posts the review via pr-comment with a footer; re-review works on re-request.
2. **Ticket slice:** `ticket-work start` takes the top of ticket-queue (filters, scoring, optional re-rank), transitions the ticket, launches an interactive agent in its own tmux window and worktree; the agent brainstorms, implements, opens a draft PR and reports done; the window closes; `sync` transitions the ticket on merge.
3. **Review response:** a new comment on your PR resumes a fork of the same session in a new window; it makes the fixes in a disposable checkout and drafts replies; you confirm, and they are committed, pushed and posted.
4. **Base:** the jobsctl cap is enforced and reorder works; needs-input and done notifications are routed; the awkit dashboard shows the attention list and chains and drills into tool TUIs.
5. **Every tool works standalone** with README, `schemas/`, tests and safe public defaults.

## Non-goals for v1

- iTerm or other terminals
- GitHub/GitLab issues or other ticket providers
- External docs and documentation drift catch-up
- Auto-approve or auto-merge switched on (mechanisms exist, shadow only)
- Auto-applying improvements
- Multi-user or team features
- A web UI
- Cloud execution
- Tamper-proof audit
- Secret stores (env only)
- Placement rulesets beyond a shared session with a window per agent
- Spend enforcement beyond review-watch's daily round limit, a count of started reviews with default 50 (spend is analytics only)
- A dollar spend cap for review-watch: planned for a 1.x release after review-run reports `cost_usd` on its run object (0.x has the daily round limit)
- memoctl features planned for later releases, not 0.x: global notes (`--global`), `export`, `compact`, a `browse` picker and FTS5 search with ranking

## claude-session spike

Done (2026-10-29, Claude Code 2.1.312). Results are summarized in architecture section 8.6 and recorded in detail in claude-session's `docs/design.md`; claude-session's `live` test suite re-checks them against new Claude Code versions. Behaviors still to verify are listed there.

## Hook feature candidates

Hook points that tool design sessions identify as useful to others (architecture section 20, "All tools"). This list is maintained as designs proceed; each entry names the tool, the hook, when it fires and who would use it.

The notifier tools (slack-notice, ha-notice, wsl-notice) are stateless and have no hooks in 0.x. notice-route has one hook, `post-fail`, listed at the end of the table.

| Tool | Hook | When it fires | Who would use it |
|---|---|---|---|
| claude-session | `pre-launch` | Before a session's `claude` process starts (after refusal checks); can veto or escalate | Policies on launching sessions (e.g. a gatectl policy), the harness |
| termctl | `pre-open` | Before termctl creates a window (after placement is resolved); can veto or escalate | Policies on window creation (e.g. no new windows during focus time), the harness |
| wtctl | `pre-remove` | After removal checks and confirmation, right before a worktree or throwaway is deleted; can veto or escalate | Policies on deleting work (e.g. keep worktrees of unmerged tickets), the harness |
| jobsctl | `pre-add` | Before a job is enqueued (shipped in jobsctl 0.35.0); can veto (exit 11) or escalate (exit 13, nothing stored: there is no held state for a job that does not exist, and `add` has no override) | Policies on enqueueing work, the harness |
| agent-spawn | `pre-launch` | Before an agent's worktree, session or window is created; can veto or escalate | Policies on starting agents (e.g. a cap on agents per repo), the harness |
| agent-spawn | `pre-teardown` | Before an agent's worktree is removed or released and its session forgotten; can veto or escalate | Policies on deleting work (e.g. keep agents of unmerged tickets), the harness |
| forgectl | `pre-merge` | After forgectl's checks and confirmation, before the merge call; can veto or escalate | Policies on merging (e.g. a gatectl policy), the harness |
| forgectl | `pre-post` | Before a review, comment, reply, approval, `resolve` or `unresolve` reaches the host; can veto or escalate; bodies are not in the payload | Policies on posting and approving, the harness |
| pr-comment | `pre-post` | After pr-comment's confirmation, before each forgectl write; carries the draft's view (moved findings, neutralized mentions, actor), the `plan_sha256`, the draft's anchor head and upper-bound counts of links, images and raw HTML in the untrusted text, and, on a per-hook opt-in, the final bodies; can veto or escalate | Policies on what is posted (e.g. a secret scanner over review text), the harness |
| review-run | `pre-run` | After review-run resolves the PR and its config, before its run record exists and before any diff is read or a session is launched; can veto or escalate; the payload carries the PR, skill, mode, previous run and the head sha at resolve time, the PR facts (draft, bot author, fork, whether the base is the default branch), whether the repo's configured code run will execute and in which sandbox mode, the session's sandbox level, subagent setting, profile kind and setting sources, the PR's size counts, and whether a human overrode an earlier escalation, never PR text | Policies on starting reviews (e.g. a gatectl policy or a cost cap), the harness |
| pr-watch | `on-<event>`, `post-poll` | `on-pushed`, `on-comment`, `on-review_comment`, `on-review`, `on-approved`, `on-changes_requested`, `on-ci`, `on-ready`, `on-merged` and `on-closed` fire once per stored event after its PR's transaction committed (best-effort, at-most-once, run in a bounded pool inside the poll, capped per poll and per PR except `merged`, `closed` and `post-poll`, which are exempt; cannot veto; payload is the metadata-only event); `post-poll` fires after a `poll` in which a PR failed, a host call returned an error or a PR became unreachable, with counts, error codes and the newly unreachable PRs | Notifications (notice-route), review-respond, ticket-work and the harness (early triggers), failure alerts |
| review-watch | `pre-round` | Once per round, at creation, after review-watch's scope, skip and round-limit checks and before capacity and before any run is started; can veto (recorded as a skip, `hook_veto`, re-asked only on a new head or `rerun`) or escalate (the round is created `held`, continued with `resume`); the payload carries the PR, item, round number, head sha, tier and reasons, the trigger and whether a human forced it, never PR or model text | Policies on starting reviews (e.g. a gatectl policy), the harness |
| review-watch | `post-draft`, `post-attention`, `post-post` | `post-draft` when a round reaches `drafted` (no gate fields; read them with `show`); `post-attention` once per cause with a `reason` (`escalated`, `stale`, `failed`, `round_limit`, `daily_limit`, `poll_failed`, `submit_failed`, `post_failed`) and an `object_type` of `round`, `item` or `host`; `post-post` when a round is posted (best-effort, delivered at least once through an outbox with `event_id`, cannot veto; payloads carry ids, shas, counts and enums, never text) | Notifications (notice-route), the harness (attention list) |
| ticketctl | `pre-transition`, `pre-create` (and the `pre-` and `post-` family for `comment`, `update` and `sprint`) | After the plan and the confirmation, right before the first provider write; can veto or escalate; payloads carry the key, site, project, status change, assignee, type, priority and sprint facts, changed field names, plan hash and body sizes and hashes, never ticket text | Policies on ticket transitions and creation (for example a gatectl policy), notifications, the harness |
| ticket-queue | `pre-claim` (a 1.x candidate, not shipped in 0.x) | Before a claim is written by `claim` or `next --claim`; a veto would pass over that ticket for `next --claim` and exit 11 for `claim KEY`; the payload would carry the key, site, board, holder and labels, never ticket text | Policies on starting work (for example a cap on claimed tickets), the harness |
| ticket-queue | `post-claim`, `post-release`, `post-auto-skip`, `post-refresh` (fires on changes), `post-rerank` (failed runs only) | After the event committed, delivered at least once through an outbox with `event_id` by the writing commands, cannot veto; payloads carry keys, ids, `seq` and enums, never ticket text | Notifications (notice-route), ticket-work and the harness |
| ticket-work | `pre-enqueue`, `pre-transition`, `pre-launch`, `post-link`, `post-status`, `post-start-failed`, `post-pending`, `post-attention` | `pre-` hooks run before the queued start, the ticket transition and the agent launch and can veto; `post-` hooks fire after the event committed, delivered at least once through an outbox with `event_id`, cannot veto; `post-attention` carries a closed `reason` (`restore_failed`, `pr_idle`, `pr_closed_unmerged`, `superseded`, `ticket_diverged`, `candidate_link`, `teardown_refused`, `agent_blocked`, `agent_failed`, `job_held`, `job_failed`, `pending_expired`, `sync_failed`, `sprint_failed`, `claim_lost`, `agent_missing`, `rule_failed`); `post-attention`, `post-pending` and `post-start-failed` payloads carry a `dedupe_key`; payloads carry keys, ids and enums, never ticket text | Notifications (notice-route) and the harness |
| notice-route | `post-fail` | After a destination failure was surfaced: run by the next `flush`, once per error code and destination per UTC day, queue events once per UTC hour; best effort, at most once, cannot veto; the payload carries the destination name, the code, the outcome, the attempts, the failing row's id as `event_id`, the failed notification's labels, `notification_source` and `notification_level` and the destination kind, never text; the payload is also routed through the router's own rules as source `notice-route`; `send` refuses to run inside a notice-route hook | Scripts that alert in their own way; the harness (attention list) |
| review-respond | `pre-round`, `pre-push` | `pre-round` once per round after the eligibility, settle and round-limit checks and before the job is submitted (a veto stops rounds of the PR until a new comment or a human `respond`; an escalation stops them until a human `respond`, which runs the hook again unless it is given `--override-escalation`); `pre-push` in `confirm` after the preconditions and before the commit and push (veto or escalate); payloads carry the PR, round, head sha, counts and the diff hash, never comment or diff text | Policies on starting responses and on pushing (for example a gatectl policy), the harness |
| review-respond | `post-pending`, `post-attention`, `post-confirm` | After the event committed, delivered at least once through an outbox with `event_id` and `dedupe_key`, cannot veto; `post-attention` carries a closed `reason` (`escalated`, `failed`, `round_limit`, `pending_expired`, `confirm_incomplete`, `remote_moved`, `push_failed`, `reply_failed`, `job_lost`, `ineligible_comment`, `pr_closed`, `teardown_refused`, `no_agent`); payloads carry ids, shas, counts and enums and the booleans `reads_third_party` and `tainted`, never text | Notifications (notice-route) and the harness |
| memoctl | `post-add` (a candidate, not scheduled; not shipped in 0.x) | After a note is committed; the payload would carry the id, repo, topic, kind, labels, size and `event_id`, never the note text | Notifications such as "an agent left a note" (notice-route), the harness |
| memoctl | `pre-add` (a candidate, not scheduled; weak, because the author kind is claimed) | Before a note is stored; veto only | Policies on what agents may record, the harness |
