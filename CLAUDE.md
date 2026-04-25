# Claude Code Routines — Operator Guide

This repo is the source of truth for four cloud routines hosted on
Anthropic's Claude Code platform. Files in `routines/*.prompt.md` are the
versioned prompts; the cloud manages execution.

## Routine inventory

`trigger_id`s are pinned in each file's YAML frontmatter — never change
them. A new value means a new cloud routine, not an update.

| Routine | File basename | Cron (UTC) |
| --- | --- | --- |
| Daily Polish | `daily-polish` | `0 4 * * *` |
| The Custodian | `custodian` | `0 7 * * *` |
| Morning Briefing | `morning-briefing` | `0 10 * * *` |
| Weekly Scorecard | `weekly-scorecard` | `0 10 * * 1` |

Files live under `routines/<basename>.prompt.md`.

## Deploying a prompt change

The cloud routine has its own copy of each prompt. Editing a `.prompt.md`
file does **not** change cloud behaviour on its own — the change must be
pushed to the Anthropic Routines API.

### Canonical: GitHub Action on push to `main`

`.github/workflows/deploy-routines.yml` watches `routines/**.prompt.md`
and runs `anthropics/claude-code-action@v1`. The action's instructions
live in `.github/workflows/deploy-routines.prompt.md` — keeping the
deploy prompt out of the YAML so it's diff-friendly and easy to edit.

Auth is `CLAUDE_CODE_OAUTH_TOKEN` (sync'd from Doppler
`gh-workflow-tokens/prd` via `secrets-sync`). The action gives Claude
the built-in `RemoteTrigger` tool, which talks to Anthropic's
internal Routines API. Verification (live `get` vs. file body) is part
of the same run.

### Manual fallback: `/schedule update` from the CLI

In any Claude Code session:

```text
> /schedule list      # confirm trigger_id
> /schedule update    # pick the routine, paste the new prompt
```

Use this only when CI is unavailable. Do **not** paste into the web UI —
the whole point of versioning these files is keeping cloud and repo in
lockstep.

## Hard rules for routine prompts

These rules apply to every routine that mutates GitHub state. Bake them
into the prompt body, not into developer memory — the cloud sandbox
cannot read this file at run-time. The block in
`routines/daily-polish.prompt.md` mirrors the list below; edit both.

1. **No local commits.** The cloud sandbox has no GPG/SSH key. Any
   `git commit` produces an unsigned commit, blocked by the
   `required_signatures` ruleset on every JacobPEvans repo. Use the
   GitHub Contents API (`gh api repos/.../contents/<path> -X PUT`);
   those commits land web-flow signed.
2. **No local branches either.** Use `gh api repos/.../git/refs` for
   branch creation, not `git checkout -b … && git push`.
3. **No `Write` / `Edit` tools when the routine writes to GitHub.**
   Strip them from `allowed_tools` so the agent cannot fall back to
   local file edits + `git commit`. The allowlist is the actual
   enforcement; prompt prose is guidance.
4. **No fictional env vars.** The cloud sandbox does not inject a
   session-ID variable. References like
   `${CLAUDE_CODE_REMOTE_SESSION_ID}` render literally. If you need a
   session link, there isn't one.

## Out of scope for this repo

- Cron, MCP connectors, environment variables, run history — managed in
  the web UI at `claude.ai/code/routines`.
- Per-run secrets — stored in the cloud environment (`env_*`).
