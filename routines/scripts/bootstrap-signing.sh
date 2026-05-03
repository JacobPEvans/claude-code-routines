#!/usr/bin/env bash
# Configure SSH commit signing for cloud routines.
# Sourced by every routine prompt as the first step:
#
#   set -o pipefail
#   curl -fsSL https://raw.githubusercontent.com/JacobPEvans/claude-code-routines/main/routines/scripts/bootstrap-signing.sh | bash
#
# pipefail is required so a curl 4xx/5xx aborts instead of bash running
# an empty body. See docs/BOT_SETUP.md for one-time identity setup and
# the git-signing rule in JacobPEvans/ai-assistant-instructions for
# the broader architecture.

set -euo pipefail

: "${CLAUDE_ROUTINES_SSH_SIGNING_KEY:?env var unset; set in the cloud routine env}"
: "${CLAUDE_ROUTINES_BOT_EMAIL:?env var unset; use the bot users.noreply.github.com address}"
: "${CLAUDE_ROUTINES_BOT_USERNAME:=claude-routines-bot}"

KEY="${HOME}/.ssh/routines_signing"
mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
printf '%s\n' "${CLAUDE_ROUTINES_SSH_SIGNING_KEY}" > "${KEY}"
chmod 600 "${KEY}"

ssh-keygen -y -f "${KEY}" >/dev/null

git config --global gpg.format ssh
git config --global user.signingkey "${KEY}"
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global user.name "${CLAUDE_ROUTINES_BOT_USERNAME}"
git config --global user.email "${CLAUDE_ROUTINES_BOT_EMAIL}"
