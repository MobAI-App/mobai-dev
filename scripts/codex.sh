#!/bin/sh
# MobAI cloud-agent setup for Codex sandboxes.
#
# Served from https://mobai.run/cloud/codex.sh so it can be fixed without
# anyone re-pasting it into their environment settings. What users paste is the
# one-liner that fetches this file.
#
# Codex differs from the other platforms in one way that shapes this whole
# script: its sandbox proxy refuses the connection a tailnet join needs
# (measured: HTTP protocol upgrades return 403 on 443 and 80, while ordinary
# requests to the same hosts succeed). So this script does not install
# Tailscale and a Codex session cannot reach a physical phone. Everything else
# works: previews, builds through the build backend, and simulators.
#
# The version is pinned rather than resolved from "latest": resolving is a
# server-side redirect this sandbox refuses (403), while a plain asset
# download works. Bump this on every release.
MOBAI_VERSION=1.0.0

set -eu

echo "mobai setup: Codex (preview, builds and simulators; no physical phone here)"

# The phone needs a tailnet and Codex cannot join one. Say so now rather than
# let someone discover it an hour in.
if [ -n "${MOBAI_TAILSCALE_KEY:-}" ]; then
  echo "" >&2
  echo "note: MOBAI_TAILSCALE_KEY is set, but Codex sandboxes cannot join a" >&2
  echo "tailnet (the proxy blocks the connection), so this script skips" >&2
  echo "Tailscale and your phone stays out of reach from here. Previews," >&2
  echo "builds and simulators still work." >&2
fi

BIN="$HOME/.mobai/bin"
mkdir -p "$BIN"
case "$(uname -m)" in
  x86_64)          ARCH=amd64 ;;
  aarch64|arm64)   ARCH=arm64 ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# 1. Headless mobai.
if [ ! -x "$BIN/mobai-dev" ]; then
  echo "downloading mobai"
  curl -fsSL -o "$BIN/mobai-dev" \
    "https://github.com/MobAI-App/mobai-dev/releases/download/v$MOBAI_VERSION/mobai-dev_linux_${ARCH}"
  chmod +x "$BIN/mobai-dev"
fi

# 2. The account. Previews are free but not anonymous: the engine is handed
#    its permission to run by mobai-dev, which needs a credential. Codex has a
#    real secrets store, so MOBAI_API_KEY is the way; the binary reads it from
#    the environment on every command, nothing to store here.
if [ -z "${MOBAI_API_KEY:-}" ]; then
  echo "" >&2
  echo "note: MOBAI_API_KEY is not set. Add it to this environment's secrets" >&2
  echo "(the MobAI desktop app creates one), or an agent can sign in with:" >&2
  echo "  $BIN/mobai-dev login --email <account email>" >&2
  echo "  $BIN/mobai-dev login --email <account email> --code <emailed code>" >&2
fi

# 3. Agent guidance. Codex reads skills from ~/.agents/skills; per-project
#    preview guidance is installed by `mobai-dev setup --agent codex` inside
#    the repo, which is the first thing an agent should run there.
cat <<'DONE'

installed: mobai-dev

In a project, start with:
  ~/.mobai/bin/mobai-dev setup --agent codex --framework <flutter|react-native|swiftui>
It writes .mobai/config.json, prints what this machine still needs, and
installs the previewing-mobile-apps skill that teaches the agent the rest:
previews, mocking, adapters, builds and simulators.

Not available on Codex yet: driving a physical phone (the sandbox blocks the
connection it needs). Use Claude Code or Cursor for that.
DONE
