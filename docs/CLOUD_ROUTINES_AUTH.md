# Cloud Routines — Authentication & Identity

Architecture lives in
[`agentsmd/rules/git-signing.md`](https://github.com/JacobPEvans/ai-assistant-instructions/blob/main/agentsmd/rules/git-signing.md).
This file is the operator runbook only.

## What runs where

- **Identity**: GitHub App
  [`jacobpevans-claude`](https://github.com/settings/apps/jacobpevans-claude),
  installed org-wide.
- **Auth**: long-lived fine-grained PAT (`claude-routines-runtime`,
  Jacob's account, 1-year expiry, all repos, scopes:
  `Contents:write`, `Pull requests:write`, `Issues:write`,
  `Metadata:read`. Custodian needs `Issues:write` for label edits,
  comment posting, and the repo-audit issue it creates.).
- **Signing**: GitHub web-flow. Every commit landed via Contents API is
  signed automatically.

## Doppler-stored credentials (`gh-workflow-tokens/prd`)

- `GH_APP_CLAUDE_BOT_ID` — future GH Actions App-token mints.
- `GH_APP_CLAUDE_BOT_NAME` — reference value (= `JacobPEvans-claude`).
- `GH_APP_CLAUDE_BOT_PRIVATE_KEY` — future GH Actions App-token mints.
- `GH_APP_CLAUDE_SSH_SIGNING_KEY` — Phase 3 GH Actions wrapper for
  `claude-code-action@v1`.
- `CLAUDE_ROUTINES_PAT` — Anthropic shared cloud env (`GH_TOKEN`).

`GH_APP_CLAUDE_*` is distributed to repos via `secrets-sync`.
`CLAUDE_ROUTINES_PAT` is **not** — it lives only in Doppler and the
Anthropic cloud env.

## Anthropic shared routine env

Set once at <https://claude.ai/code/routines> on the env shared by all
five routines. Values:

- `GH_TOKEN` — Doppler `CLAUDE_ROUTINES_PAT`.
- `GIT_AUTHOR_NAME` — `JacobPEvans-claude[bot]`.
- `GIT_AUTHOR_EMAIL` — the App's no-reply form. GitHub uses the
  lowercase App slug, not the display name:
  `<APP_ID>+jacobpevans-claude[bot]@users.noreply.github.com`.
- `GIT_COMMITTER_NAME` — same as `GIT_AUTHOR_NAME`.
- `GIT_COMMITTER_EMAIL` — same as `GIT_AUTHOR_EMAIL`.

Find the literal `<APP_ID>` value at
<https://github.com/settings/apps/jacobpevans-claude> (URL bar shows
the numeric ID; or `gh api /app -H "Authorization: Bearer $JWT" --jq .id`
once you've minted a JWT from the private key).

## Annual PAT rotation

```bash
# 1. Mint replacement
open https://github.com/settings/tokens?type=beta

# 2. Update Doppler
doppler secrets set CLAUDE_ROUTINES_PAT='<new-token>' \
  -p gh-workflow-tokens -c prd

# 3. Re-paste GH_TOKEN into Anthropic shared env (web UI)
open https://claude.ai/code/routines

# 4. Verify
gh workflow run deploy-routines.yml --ref main
# Wait for any routine run, then:
gh api repos/JacobPEvans/<recently-mutated-repo>/pulls/<N>/commits \
  --jq '.[].commit.verification | {verified, reason}'
# Expect: every entry {verified: true, reason: "valid"}

# 5. Revoke old PAT
open https://github.com/settings/tokens
```

## Compromise response

PAT leaked: revoke at
<https://github.com/settings/tokens>, mint replacement, run rotation
above.

App private key leaked: regenerate at
<https://github.com/settings/apps/jacobpevans-claude>, update Doppler
`GH_APP_CLAUDE_BOT_PRIVATE_KEY`, `secrets-sync` propagates. App
credentials don't currently flow to the routine env, so no routine env
update is required.
