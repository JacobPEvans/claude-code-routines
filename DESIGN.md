# Design History

How these routines came to be, what shaped them,
and lessons learned along the way.

## The Problem (April 2026)

42+ GitHub repos generating constant noise:

- **50+ open PRs** — 80% from Renovate/Dependabot,
  most with green CI, sitting unmerged
- **50+ open issues** — many `[aw]` agentic workflow
  failure reports, stale and self-resolved
- **Stale branches** — merged PRs leaving orphan
  branches across repos
- **~7 dormant repos** — approaching "abandoned"
  territory with no recent commits

A single read-only "GitHub Daily Digest" trigger
posted a summary to Slack each morning. It reported
problems but never fixed anything.

## Inspiration

[githubnext/agentics][agentics] — GitHub's own
collection of agentic workflow examples. Patterns
like `repo-assist` (weighted task rotation),
`issue-arborist` (issue graph management), and
`issue-triage` (classification + labeling) directly
influenced the design.

[agentics]: https://github.com/githubnext/agentics

## Design Session (April 16, 2026)

Five option packages were designed and evaluated:

| # | Name               | Architecture        |
|---| ------------------ | ------------------- |
| 1 | The Custodian      | Single cloud, tasks |
| 2 | The Groundskeeper  | Local-only, disk    |
| 3 | Briefing + Sweep   | Hybrid read/write   |
| 4 | The Issue Arborist | Issue graph focus   |
| 5 | Impression Engine  | Polish + scoring    |

### What Was Chosen: Combination A

All 5 routines — "The Complete Estate" — with zero
scope overlap. Each routine owns a distinct domain.
The Groundskeeper (local branch pruning) was
scoped to local-only tasks, while the other 4
deploy as cloud triggers.

### Key Design Decisions

**Weighted random rotation (Custodian)**:
Instead of doing the same thing every day, The
Custodian picks 2 tasks per run from a pool of 8,
weighted by impact. PR Triage (weight 25) runs
roughly every other day. Inactive Repo Scan
(weight 5) runs about once a week. Date-seeded
randomness ensures reproducible selection and
fair coverage over a ~4-day full rotation.

**Read-only morning, action evening (Briefing)**:
Safety through separation. The Morning Briefing
gives situational awareness with zero mutations.
Actions happen in The Custodian's overnight window
when the human is asleep and can review in the
morning.

**One repo per day (Daily Polish)**:
Deep-cleaning all 42 repos daily would blow the
token budget. Rotating through one per day means
every active repo gets attention within ~2 weeks.
Staleness-based ordering ensures the most neglected
repo goes first.

**Scoring rubric (Weekly Scorecard)**:
Seven factors weighted by visitor impact: README
quality (25%), commit recency (20%), open issues
(15%), CI status (15%), releases (10%), description
(10%), license (5%). Week-over-week deltas create
accountability and surface trends.

**Sonnet over Opus**:
Routines are mechanical, not architectural. They
follow explicit rules, not open-ended reasoning.
Sonnet at ~$0.36/day total (~$10.80/month) vs
Opus at ~$3.60/day ($108/month) — 10x savings
with no quality impact for this workload.

**Safety caps on every routine**:
Max 8 PR merges, 10 issue closures, 3 issue
creations, 15 branch deletions per Custodian run.
Daily Polish creates draft PRs only — never
auto-merges. Morning Briefing and Weekly Scorecard
are strictly read-only. Comment deduplication
prevents bot spam (check for existing comments
within 7 days before posting).

## The Overnight Failure (April 17, 2026)

All 4 cloud routines failed on their first
scheduled run.

**Root cause**: Every prompt relied on `gh` CLI
commands, but `gh` is not pre-installed in
Anthropic's cloud sandbox. The design session ran
locally where `gh` works, so this was never caught.

### Investigation Path

1. **GitHub MCP Connector** — explored using the
   built-in GitHub MCP server
   (`api.githubcopilot.com/mcp`). Found gaps: no
   branch deletion, no repo description updates,
   limited search capabilities. Rewriting all 4
   prompts for MCP tools was high-risk.

2. **Official docs** — the answer was simple: add
   `apt update && apt install -y gh` to the
   environment setup script (cached after first
   run) and set `GH_TOKEN` as an environment
   variable. `gh` reads it automatically.

### Signed Commits

Daily Polish creates draft PRs with file changes.
In the cloud sandbox there is no local git identity,
so `git commit` would produce unsigned commits.
The fix: use the GitHub Contents API
(`gh api repos/.../contents/...`) to create commits
server-side, signed by GitHub's web-flow key. This
satisfies branch protection rules requiring signed
commits.

### The Fix

All 4 triggers share one cloud environment. One
environment configuration change fixed all four:

1. Setup script: `apt update && apt install -y gh`
2. Environment variable: `GH_TOKEN=<PAT>`
3. Added `## Prerequisites` section to each prompt
4. Rewrote Daily Polish commit workflow for
   API-signed commits

## Token Monitoring

Estimated daily cost: ~$0.36 (Sonnet pricing).
A review checkpoint was set for April 23, 2026
(7 days post-deployment) to validate actual costs
and trim if excessive.

## What's Not Here

**The Groundskeeper** (Option 2) runs as a local
`/schedule` cron, not a cloud trigger. It handles
local branch pruning and worktree health checks —
tasks that require filesystem access. It is not
included in this repo because it runs locally and
its prompt lives in the local schedule
configuration.
