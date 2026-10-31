# Interface registry

Each tool, its current version, a link to its interface spec and its known consumers (architecture section 18.3). A session changing a tool's interface checks that tool's consumers here first, and updates this table on every interface change (design guide section 13).

- **Known consumers** are the tools whose "Uses" list in architecture section 5 includes the tool. The harness `awkit` is not listed: it consumes every tool through adapters (architecture section 7.1), and tools are never aware of it.
- **Interface spec** links are local sibling paths during development (all repos are checked out side by side). Published links will be GitHub URLs under `https://github.com/agent-workflow-kit/<repo>`.

| Tool | Layer | Version | Interface spec | Known consumers | Status |
|---|---|---|---|---|---|
| forgectl | L1 | 0.0.0 | [../forgectl/docs/interface.md](../forgectl/docs/interface.md) | pr-watch, pr-comment, review-run, review-watch, review-respond, ticket-work | pre-design |
| ticketctl | L1 | 0.0.0 | [../ticketctl/docs/interface.md](../ticketctl/docs/interface.md) | ticket-queue, ticket-create, ticket-work | pre-design |
| wtctl | L1 | 0.1.0-design | [../wtctl/docs/interface.md](../wtctl/docs/interface.md) | agent-spawn, review-run, review-respond, ticket-work | designed (2026-10-30) |
| termctl | L1 | 0.1.0-design | [../termctl/docs/interface.md](../termctl/docs/interface.md) | agent-spawn | designed (2026-10-30) |
| claude-session | L1 | 0.1.0-design | [../claude-session/docs/interface.md](../claude-session/docs/interface.md) | gatectl, ticket-queue, agent-spawn | designed (2026-10-29) |
| jobsctl | L1 | 0.1.0-design | [../jobsctl/docs/interface.md](../jobsctl/docs/interface.md) | review-watch (optional), review-respond (optional), ticket-work | designed (2026-10-31) |
| gatectl | L1 | 0.0.0 | [../gatectl/docs/interface.md](../gatectl/docs/interface.md) | review-watch (optional), review-respond (optional) | pre-design |
| memoctl | L1 | 0.0.0 | [../memoctl/docs/interface.md](../memoctl/docs/interface.md) | claude-session (optional, binding B) | pre-design |
| slack-notice | L1 | 0.0.0 | [../slack-notice/docs/interface.md](../slack-notice/docs/interface.md) | notice-route (as a configured notifier) | pre-design |
| ha-notice | L1 | 0.0.0 | [../ha-notice/docs/interface.md](../ha-notice/docs/interface.md) | notice-route (as a configured notifier) | pre-design |
| desktop-notice | L1 | 0.0.0 | [../desktop-notice/docs/interface.md](../desktop-notice/docs/interface.md) | notice-route (as a configured notifier) | pre-design |
| pr-watch | L2 | 0.0.0 | [../pr-watch/docs/interface.md](../pr-watch/docs/interface.md) | review-watch (optional), review-respond, ticket-work | pre-design |
| pr-comment | L2 | 0.0.0 | [../pr-comment/docs/interface.md](../pr-comment/docs/interface.md) | review-run (review-draft schema only), review-watch, review-respond | pre-design |
| ticket-queue | L2 | 0.0.0 | [../ticket-queue/docs/interface.md](../ticket-queue/docs/interface.md) | ticket-work | pre-design |
| ticket-create | L2 | 0.0.0 | [../ticket-create/docs/interface.md](../ticket-create/docs/interface.md) | none | pre-design |
| notice-route | L2 | 0.0.0 | [../notice-route/docs/interface.md](../notice-route/docs/interface.md) | none (reached through user-wired hooks) | pre-design |
| agent-spawn | L2 | 0.0.0 | [../agent-spawn/docs/interface.md](../agent-spawn/docs/interface.md) | ticket-create, review-run, review-respond, ticket-work | pre-design |
| review-run | L3 | 0.0.0 | [../review-run/docs/interface.md](../review-run/docs/interface.md) | review-watch | pre-design |
| review-watch | L3 | 0.0.0 | [../review-watch/docs/interface.md](../review-watch/docs/interface.md) | none | pre-design |
| review-respond | L3 | 0.0.0 | [../review-respond/docs/interface.md](../review-respond/docs/interface.md) | none | pre-design |
| ticket-work | L3 | 0.0.0 | [../ticket-work/docs/interface.md](../ticket-work/docs/interface.md) | none | pre-design |
| session-audit | L3 (post-v1) | 0.0.0 | [../session-audit/docs/interface.md](../session-audit/docs/interface.md) | none | pre-design |
| self-improve | L3 (post-v1) | 0.0.0 | [../self-improve/docs/interface.md](../self-improve/docs/interface.md) | none | pre-design |
| awkit | L4 | 0.0.0 | [../awkit/docs/interface.md](../awkit/docs/interface.md) | none | pre-design |
