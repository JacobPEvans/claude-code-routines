# claude-code-routines

Version-controlled prompt files for
[Claude Code Routines][routines] — scheduled agents
that manage JacobPEvans's GitHub portfolio.

See [DESIGN.md](DESIGN.md) for the origin story,
design decisions, and lessons learned.

[routines]: https://docs.anthropic.com/en/docs/claude-code/routines

## Routines

| Routine                | Schedule           | Purpose                     |
| ---------------------- | ------------------ | --------------------------- |
| [Morning Briefing][mb] | Daily 5:00 AM CT   | Read-only activity summary  |
| [The Custodian][cu]    | Daily 2:00 AM CT   | Weighted-random maintenance |
| [Issue Solver][is]     | Daily 7am + 7pm CT | Solve one issue → draft PR  |
| [Daily Polish][dp]     | Daily 11:00 PM CT  | Deep-clean one repo per day |
| [Weekly Scorecard][ws] | Mondays 5:00 AM CT | Portfolio health scores     |

[mb]: routines/morning-briefing.prompt.md
[cu]: routines/custodian.prompt.md
[is]: routines/issue-solver.prompt.md
[dp]: routines/daily-polish.prompt.md
[ws]: routines/weekly-scorecard.prompt.md

## Architecture

All 5 routines share a single Claude Code cloud
environment and post results to Slack via MCP.

```text
┌─────────────┐   ┌────────────────┐   ┌───────┐
│ Cron Trigger │──▶│ Cloud Sandbox  │──▶│ Slack │
│  (Anthropic) │   │ gh + GH_TOKEN  │   │  MCP  │
└─────────────┘   └────────────────┘   └───────┘
                          │
                          ▼
                  ┌──────────────┐
                  │  GitHub API  │
                  └──────────────┘
```

## Installation

Claude Code cloud routines run in a shared environment.
Configure it at [claude.ai/code](https://claude.ai/code)
under environment settings.

```bash
# 1. Install gh CLI in the cloud sandbox (cached after first run)
apt update && apt install -y gh

# 2. Set GH_TOKEN as an environment variable in the trigger config
export GH_TOKEN=<your GitHub PAT>
```

### Setup Script

```bash
apt update && apt install -y gh
```

The result is cached after the first run —
`gh` is instantly available on subsequent sessions.

### Environment Variable

```text
GH_TOKEN=<your GitHub PAT>
```

`gh` reads `GH_TOKEN` automatically.

### Required PAT Scopes

| Scope         | Used By                              |
| ------------- | ------------------------------------ |
| `repo`        | All routines — read/write repo data  |
| `delete_repo` | Custodian — branch deletion via API  |
| `gist`        | Polish, Solver, Weekly Scorecard     |
| `workflow`    | Custodian — workflow run checks      |
| `read:org`    | All routines — org-level search      |
| `project`     | Morning Briefing — project queries   |

### MCP Connections

Each routine connects to Slack for output:

- **Name**: `Slack`
- **URL**: `https://mcp.slack.com/mcp`

## Deploying Changes

[`.github/workflows/deploy-routines.yml`][dw]
runs `anthropics/claude-code-action@v1` against
Anthropic's `RemoteTrigger` API, authenticated
with `CLAUDE_CODE_OAUTH_TOKEN`. It triggers on
`workflow_dispatch` and daily at 06:00 UTC.

After merging a prompt change to `main`, deploy
immediately with `gh workflow run deploy-routines.yml`.

The workflow's instructions live alongside it in
[`deploy-routines.prompt.md`][dpr].

See [CLAUDE.md](CLAUDE.md) for the full operator
guide, the manual `/schedule update` fallback, and
the hard rules every routine prompt must follow.

[dw]: .github/workflows/deploy-routines.yml
[dpr]: .github/workflows/prompts/deploy-routines.prompt.md

## File Structure

```text
claude-code-routines/
├── README.md
├── CLAUDE.md
├── DESIGN.md
├── .cspell.json
├── .gitignore
├── .markdownlint-cli2.yaml
├── .readme-validator.yaml
├── .github/
│   └── workflows/
│       ├── deploy-routines.yml
│       └── prompts/
│           └── deploy-routines.prompt.md
└── routines/
    ├── .markdownlint.yaml
    ├── custodian.prompt.md
    ├── daily-polish.prompt.md
    ├── issue-solver.prompt.md
    ├── morning-briefing.prompt.md
    └── weekly-scorecard.prompt.md
```

## License

MIT
