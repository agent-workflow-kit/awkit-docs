# awkit-docs

Architecture, conventions, roadmap and interface registry for `awkit` ("agent workflow kit").

## What awkit is

`awkit` is a modular, open-source system for running Claude Code agents as part of a developer's daily work:

- Watch for PRs where you are asked to review, run a reviewer agent, and let you post the result with one key.
- Pull tickets from one or more boards, rank them, and start an agent on the next one in its own git worktree and tmux window.
- Let working agents brainstorm with you, ask for your judgment, and report when they are done.
- When review comments land on a PR an agent opened, resume a fork of that same agent session to respond.
- Keep you informed (Slack, Home Assistant, desktop, tmux) when something needs you.
- Give you a TUI to see and steer all of it, while every piece stays usable on its own.

## The layered principle

1. Every tool is an ordinary standalone CLI; tools never adapt to the harness, the harness adapts to tools.
2. A tool may use tools in a lower or the same layer (like it uses `gh`), never the tools that call it, and never in a cycle.
3. The harness `awkit` is just the top-layer tool; it knows the others only through configuration and adapters.

## Documents

| Document | Contents |
|---|---|
| [architecture.md](architecture.md) | System design: cross-tool contracts, ownership of responsibilities, safety invariants, per-tool constraints and open topics (section 20). |
| [design-guide.md](design-guide.md) | Conventions every awkit tool follows, including the naming rules (CLI, exit codes, config, state, hooks, labels, schemas, repo layout). |
| [interface-registry.md](interface-registry.md) | Each tool's version, interface spec and known consumers. |
| [roadmap.md](roadmap.md) | Slices and build order, v1 done criteria, non-goals, the claude-session spike, hook feature candidates. |

## Repositories

One repo per tool, named exactly as the tool, plus `awkit` (the harness) and `awkit-docs` (this repo). All repos are public in the [`agent-workflow-kit`](https://github.com/agent-workflow-kit) GitHub organization; install a tool with `uv tool install git+https://github.com/agent-workflow-kit/<repo>`. Tools carry no shared prefix (design guide section 1).

| Repo | Layer | Purpose |
|---|---|---|
| forgectl | L1 | Normalized access to pull/merge requests across GitHub and GitLab. |
| ticketctl | L1 | Normalized ticket access (Jira first). |
| wtctl | L1 | Git worktrees, throwaway checkouts, and the repo id to local clone mapping. |
| termctl | L1 | Terminal placement (tmux backend). |
| claude-session | L1 | Runs and supervises Claude Code sessions. |
| jobsctl | L1 | Generic job queue with concurrency caps and ordering. |
| gatectl | L1 | Policy decisions with first-class shadow mode. |
| memoctl | L1 | Uncommitted shared knowledge for agents. |
| slack-notice | L1 | Slack notification channel. |
| ha-notice | L1 | Home Assistant notification channel. |
| desktop-notice | L1 | Native desktop notification channel. |
| pr-watch | L2 | Watches PRs for changes and emits events. |
| pr-comment | L2 | Posts reviews, replies and comments to PRs. |
| ticket-queue | L2 | "Which ticket should I do next?" |
| ticket-create | L2 | Skill-wrapper: draft and create tickets. |
| notice-route | L2 | Routes notifications to channels. |
| agent-spawn | L2 | Launch, resume, park and tear down agents (worktree + terminal + Claude session). |
| review-run | L3 | Skill-wrapper: run a review skill on a PR. |
| review-watch | L3 | Watches for review requests and runs reviews unattended, as drafts you accept. |
| review-respond | L3 | Responds to review comments on your PRs. |
| ticket-work | L3 | Owns the lifecycle of a worked ticket. |
| session-audit | L3 (post-v1) | Skill-wrapper: analyze transcripts and outcomes. |
| self-improve | L3 (post-v1) | Skill-wrapper: turn audit findings into proposed edits. |
| awkit | L4 | The harness: registry, adapters, state graph, rules, tick/run loop, dashboard. |
| awkit-docs | - | This repo. |

## License

MIT. See [LICENSE](LICENSE).
