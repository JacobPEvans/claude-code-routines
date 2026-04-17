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
| [Daily Polish][dp]     | Daily 11:00 PM CT  | Deep-clean one repo per day |
| [Weekly Scorecard][ws] | Mondays 5:00 AM CT | Portfolio health scores     |

[mb]: routines/morning-briefing.prompt.md
[cu]: routines/custodian.prompt.md
[dp]: routines/daily-polish.prompt.md
[ws]: routines/weekly-scorecard.prompt.md

## Architecture

All 4 routines share a single Claude Code cloud
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

## Environment Setup

Claude Code cloud routines run in a shared environment.
Configure it at [claude.ai/code](https://claude.ai/code)
under environment settings.

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
| `gist`        | Daily Polish, Weekly Scorecard       |
| `workflow`    | Custodian — workflow run checks      |
| `read:org`    | All routines — org-level search      |
| `project`     | Morning Briefing — project queries   |

### MCP Connections

Each routine connects to Slack for output:

- **Name**: `Slack`
- **URL**: `https://mcp.slack.com/mcp`

## Deploying Changes

Prompt files in this repo are the source of truth.
To deploy an update:

1. Edit the `*.prompt.md` file
2. Copy the full file content (including frontmatter)
3. Update the routine at [claude.ai/code][cac]
   via the triggers UI

[cac]: https://claude.ai/code

The YAML frontmatter documents the deployed
configuration but is not parsed by the trigger
system — the actual configuration lives in the
Claude Code platform.

## File Structure

```text
claude-code-routines/
├── README.md
├── DESIGN.md
├── .cspell.json
├── .gitignore
├── .markdownlint-cli2.yaml
└── routines/
    ├── .markdownlint.yaml
    ├── custodian.prompt.md
    ├── daily-polish.prompt.md
    ├── morning-briefing.prompt.md
    └── weekly-scorecard.prompt.md
```

## License

MIT
