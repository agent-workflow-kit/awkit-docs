# Roadmap

Derived from `architecture.md` (v1.6), sections 8.6, 18.2 and 19. If this file and the architecture disagree, the architecture wins; update this file.

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

The first task in the claude-session design session (architecture section 8.6). Empirically confirm:

- [ ] `--plugin-dir` is additive with user-level and project-level standalone skills;
- [ ] hooks from `--settings` merge with existing user hooks;
- [ ] behavior of `--resume` with respect to plugin dirs and settings;
- [ ] whether `--resume` keeps or changes the Claude session id, and whether `--session-id <uuid>` can pre-assign it;
- [ ] Stop-hook blocking works as described (headless);
- [ ] headless `-p` JSON output includes the session id, `result` and `total_cost_usd`, and `claude_session_id` can be captured in both modes from the SessionStart payload, including its start source (`startup`, `resume`, `clear`);
- [ ] prompt delivery: the short bootstrap prompt in argv plus `$CSESSION_DIR/prompt.md` works in both modes, and headless runs accept the prompt on stdin;
- [ ] `PostToolUse` fires after an answered permission prompt, so it can clear `needs-input(permission)`;
- [ ] clean shutdown by signaling the exact `claude` child PID after Stop (auto-exit);
- [ ] credential isolation for third-party-reading kinds (architecture section 13.1): pointing `GH_CONFIG_DIR`/`GLAB_CONFIG_DIR` at an empty temp dir hides git-host logins without affecting Claude's own auth;
- [ ] `--setting-sources` can exclude user and project settings (and CLAUDE.md) for third-party-reading kinds, so user allow rules cannot widen their profiles; if exclusion is impossible, conservative profiles are expressed as deny rules;
- [ ] `--strict-mcp-config` with no servers leaves the session without MCP servers;
- [ ] `--fork-session` with `--resume` creates a new Claude session id, leaves the original conversation unchanged and resumable, and the fork is itself resumable by its new id;
- [ ] for the respond profile (architecture section 13.1): `git push` and other network access are unreachable, the user's tmux server socket is unreachable, and Claude Code's sandbox (with network denied) works where available.

## Hook feature candidates

Hook points that tool design sessions identify as useful to others (architecture section 20, "All tools"). This list is maintained as designs proceed; each entry names the tool, the hook, when it fires and who would use it.

_None yet._
