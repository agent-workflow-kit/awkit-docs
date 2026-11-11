# Roadmap

Derived from `architecture.md` (v1.17), sections 8.6, 18.2 and 19. If this file and the architecture disagree, the architecture wins; update this file.

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
| Tickets | ticketctl → ticket-queue → ticket-work (needs base + forgectl + pr-watch) |
| Notify | slack-notice, ha-notice, desktop-notice → notice-route |
| Response | review-respond (needs base + pr-watch + pr-comment) |
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
- Spend enforcement beyond review-watch's optional, off-by-default daily cap (spend is analytics only)

## claude-session spike

Done (2026-10-29, Claude Code 2.1.312). Results are summarized in architecture section 8.6 and recorded in detail in claude-session's `docs/design.md`; claude-session's `live` test suite re-checks them against new Claude Code versions. Behaviors still to verify are listed there.

## Hook feature candidates

Hook points that tool design sessions identify as useful to others (architecture section 20, "All tools"). This list is maintained as designs proceed; each entry names the tool, the hook, when it fires and who would use it.

| Tool | Hook | When it fires | Who would use it |
|---|---|---|---|
| claude-session | `pre-launch` | Before a session's `claude` process starts (after refusal checks); can veto or escalate | Policies on launching sessions (e.g. a gatectl policy), the harness |
| termctl | `pre-open` | Before termctl creates a window (after placement is resolved); can veto or escalate | Policies on window creation (e.g. no new windows during focus time), the harness |
| wtctl | `pre-remove` | After removal checks and confirmation, right before a worktree or throwaway is deleted; can veto or escalate | Policies on deleting work (e.g. keep worktrees of unmerged tickets), the harness |
| jobsctl | `pre-add` | Before a job is enqueued; can veto (an escalation would need a held-before-queued state, so it is not in v1) | Policies on enqueueing work, the harness |
| agent-spawn | `pre-launch` | Before an agent's worktree, session or window is created; can veto or escalate | Policies on starting agents (e.g. a cap on agents per repo), the harness |
| agent-spawn | `pre-teardown` | Before an agent's worktree is removed or released and its session forgotten; can veto or escalate | Policies on deleting work (e.g. keep agents of unmerged tickets), the harness |
| forgectl | `pre-merge` | After forgectl's checks and confirmation, before the merge call; can veto or escalate | Policies on merging (e.g. a gatectl policy), the harness |
| forgectl | `pre-post` | Before a review, comment, reply, approval, `resolve` or `unresolve` reaches the host; can veto or escalate; bodies are not in the payload | Policies on posting and approving, the harness |
| pr-comment | `pre-post` | After pr-comment's confirmation, before each forgectl write; carries the draft's view (moved findings, neutralized mentions, actor), the `plan_sha256`, the draft's anchor head and upper-bound counts of links, images and raw HTML in the untrusted text, and, on a per-hook opt-in, the final bodies; can veto or escalate | Policies on what is posted (e.g. a secret scanner over review text), the harness |
| review-run | `pre-run` | After review-run resolves the PR and its config, before its run record exists and before any diff is read or a session is launched; can veto or escalate; the payload carries the PR, skill, mode, previous run and the head sha at resolve time, the PR facts (draft, bot author, fork, whether the base is the default branch), whether the repo's configured code run will execute and in which sandbox mode, the session's sandbox level, subagent setting, profile kind and setting sources, the PR's size counts, and whether a human overrode an earlier escalation, never PR text | Policies on starting reviews (e.g. a gatectl policy or a cost cap), the harness |
| pr-watch | `on-<event>`, `post-poll` | `on-pushed`, `on-comment`, `on-review_comment`, `on-review`, `on-approved`, `on-changes_requested`, `on-ci`, `on-ready`, `on-merged` and `on-closed` fire once per stored event after its PR's transaction committed (best-effort, at-most-once, run in a bounded pool inside the poll, cannot veto; payload is the metadata-only event); `post-poll` fires after a `poll` that had errors or in which PRs became unreachable, with counts, error codes and the newly unreachable PRs | Notifications (notice-route), review-respond, ticket-work and the harness (early triggers), failure alerts |
