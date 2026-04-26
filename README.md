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

## Usage

Prompt files are the source of truth. Deploy via
the `RemoteTrigger` tool inside a Claude Code session:

**Update an existing trigger** (use the `trigger_id`
from the prompt file's frontmatter):

```text
RemoteTrigger(action="update", trigger_id="trig_...",
  body={"job_config": {"ccr": {"events": [{"data":
    {"message": {"content": "<prompt body>",
      "role": "user"}, "type": "user"}}],
    "session_context": {"allowed_tools": [...],
      "model": "claude-sonnet-4-6"}}}})
```

**Create a new trigger:**

```text
RemoteTrigger(action="create", body={"name": "...",
  "cron_expression": "...", "mcp_connections": [...],
  "job_config": {...}})
```

The prompt body is the file content below the
`---` frontmatter. The frontmatter documents the
deployed configuration (trigger ID, cron, model,
tools) but is not parsed by the trigger system.

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
    ├── issue-solver.prompt.md
    ├── morning-briefing.prompt.md
    └── weekly-scorecard.prompt.md
```

## License

MIT
