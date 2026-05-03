# claude-routines-bot — GitHub setup

A dedicated GitHub user account that exists *only* as a signing identity
for Anthropic Cloud Routines. No org membership, no repo permissions, no
2FA. Auth and pushes happen via the existing `jacobpevans-github-actions`
GitHub App's installation token.

## One-time setup

### 1. Create the GitHub user account

Sign up at <https://github.com/join>:

- **Username**: `claude-routines-bot` (or any name you prefer; pass to
  `CLAUDE_ROUTINES_BOT_USERNAME` in step 5).
- **Email**: any inbox you control. Do **not** reuse a personal email
  here — the address ends up in commit metadata and PR review threads.
  A separate Gmail / Fastmail / proton inbox is fine; subdomain
  forwarders work too.
- Verify the email immediately.

### 2. Generate the SSH signing key

```bash
ssh-keygen -t ed25519 -C "<bot-username>@<host>" -f /tmp/routines_signing -N ""
```

### 3. Register on the bot account

GitHub Settings → SSH and GPG keys → **New SSH key** → key type
**Signing Key** (NOT Authentication Key — this is the most common
mistake; an Authentication-Key registration won't make GitHub verify
commit signatures).

Confirm:

```bash
gh api users/<bot-username>/ssh_signing_keys
```

### 4. Find the bot's signing email

Once the bot account exists and the email is verified, GitHub assigns a
no-reply form at:

```text
<numeric-id>+<bot-username>@users.noreply.github.com
```

You can find the numeric ID via `gh api users/<bot-username> --jq .id`.
This is the email you want commits to record — it never leaks the
private inbox you signed up with.

### 5. Wire the cloud env

The five routines share one Anthropic Cloud Routine environment. At
<https://claude.ai/code/routines>, set three variables on the shared
env:

- `CLAUDE_ROUTINES_SSH_SIGNING_KEY` — full private key contents
  (from `/tmp/routines_signing`)
- `CLAUDE_ROUTINES_BOT_USERNAME` — the bot username
  (e.g. `claude-routines-bot`)
- `CLAUDE_ROUTINES_BOT_EMAIL` — the `users.noreply.github.com` email
  from step 4

Then securely delete the local key:

```bash
shred -u /tmp/routines_signing /tmp/routines_signing.pub  # or rm -P on macOS
```

Upload the same key to Doppler (`gh-workflow-tokens/prd`) under the same
name if you want a recoverable copy; otherwise the cloud env is the
only store.

> **Why no `secrets-sync` distribution**: the bootstrap reads the env
> from the routine sandbox, not from any GitHub Actions secret.
> Distributing the private key into every repo's Actions store would
> broaden the exfiltration surface for zero benefit. Add a scoped
> Actions secret only when (if ever) a workflow needs it.

### 6. Verify (after the prompt-rewrite PR ships)

This step requires the follow-up PR that updates routine prompts to
source `bootstrap-signing.sh`. Until then, routines still use the
Contents-API path and there's nothing to verify.

After the prompt-rewrite PR is deployed, fire Daily Polish manually
and inspect commits on the resulting draft PR:

```bash
REPO=JacobPEvans/<polished-repo>
PR=<pr-number>
gh api "repos/$REPO/pulls/$PR/commits" --jq '.[] |
  {sha:.sha[0:8], author:.author.login,
   verified:.commit.verification.verified, reason:.commit.verification.reason}'
```

Every commit should report `verified: true, reason: "valid"` with
`author.login: "<bot-username>"`. The PR itself is opened by
`jacobpevans-github-actions[bot]` (the GitHub App handling auth/push),
so don't filter `gh pr list --author <bot-username>` — that returns
zero PRs by design.

`.commit.verification` exposes `{verified, reason, signature, payload,
verified_at}`. Identity surfaces as the commit's `.author.login` /
`.committer.login`, NOT as a `.verification.signer.login` field (that
field doesn't exist).

## Revocation

If the signing key leaks:

1. Delete the SSH signing key on the bot account.
2. Generate a new key (step 2), re-register as Signing Key (step 3),
   rotate `CLAUDE_ROUTINES_SSH_SIGNING_KEY` in the cloud env (step 5).

Historical commits stay valid — GitHub doesn't invalidate signatures
when a key is deleted. New commits sign with the new key on next run.

## See also

- `../routines/scripts/bootstrap-signing.sh` — consumes these env vars
  at runtime.
- The `git-signing` rule in `JacobPEvans/ai-assistant-instructions` —
  canonical architecture doc.
