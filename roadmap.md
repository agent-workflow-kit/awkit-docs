# Roadmap

Derived from `architecture.md` (v1.8), sections 8.6, 18.2 and 19. If this file and the architecture disagree, the architecture wins; update this file.

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
3. **Review response:** a new comment on your PR resumes a fork of the same session in a new window; it commits fixes locally and drafts replies; you confirm, and they are pushed and posted.
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
