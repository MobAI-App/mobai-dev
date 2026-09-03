#!/bin/sh
# MobAI cloud-agent setup for Codex sandboxes.
#
# Served from https://mobai.run/cloud/codex.sh so it can be fixed without
# anyone re-pasting it into their environment settings. What users paste is the
# one-liner that fetches this file.
#
# Codex differs from the other platforms in one way: its sandbox proxy refuses
# the connection a tailnet join needs (measured: HTTP protocol upgrades return
# 403 on 443 and 80, while ordinary requests to the same hosts succeed). So the
# phone is out of reach here until Codex changes that. Tailscale is installed
# and tried all the same, so the day it works nothing needs re-pasting; the
# agent is told the join may fail and why. Everything else works: previews,
# builds through the build backend, and simulators.
#
# The version is pinned rather than resolved from "latest": resolving is a
# server-side redirect this sandbox refuses (403), while a plain asset
# download works. Bump this on every release.
MOBAI_VERSION=1.0.0

set -eu

echo "mobai setup: Codex (previews, builds, simulators; the phone once Codex allows a tailnet join)"

BIN="$HOME/.mobai/bin"
mkdir -p "$BIN"
case "$(uname -m)" in
  x86_64)          ARCH=amd64 ;;
  aarch64|arm64)   ARCH=arm64 ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# 1. Tailscale, static binaries so no root and no package manager is needed.
if [ ! -x "$BIN/tailscaled" ]; then
  echo "installing tailscale ($ARCH)"
  # Discover the current version, with retries because sandbox egress proxies
  # hiccup; fall back to a pinned version rather than dying. The pipeline hides
  # curl's exit code from set -e, so the empty-version case must be handled
  # explicitly or a failure here cascades into a 404 fed to tar.
  TS_VER=""
  for _ in 1 2 3; do
    TS_VER=$(curl -fsSL "https://pkgs.tailscale.com/stable/?mode=json" 2>/dev/null | sed -n 's/.*"TarballsVersion": *"\([^"]*\)".*/\1/p')
    [ -n "$TS_VER" ] && break
    sleep 2
  done
  [ -n "$TS_VER" ] || TS_VER=1.98.10
  TS_TGZ=/tmp/tailscale.tgz
  if ! curl -fsSL --retry 3 -o "$TS_TGZ" "https://pkgs.tailscale.com/stable/tailscale_${TS_VER}_${ARCH}.tgz"; then
    echo "could not download tailscale $TS_VER ($ARCH) - check that pkgs.tailscale.com is allowed" >&2
    exit 1
  fi
  tar xzf "$TS_TGZ" -C "$BIN" --strip-components=1 \
    "tailscale_${TS_VER}_${ARCH}/tailscale" \
    "tailscale_${TS_VER}_${ARCH}/tailscaled"
  rm -f "$TS_TGZ"
fi


# 2. Headless mobai.
if [ ! -x "$BIN/mobai-dev" ]; then
  echo "downloading mobai"
  curl -fsSL -o "$BIN/mobai-dev" \
    "https://github.com/MobAI-App/mobai-dev/releases/download/v$MOBAI_VERSION/mobai-dev_linux_${ARCH}"
  chmod +x "$BIN/mobai-dev"
fi

# 3. The mobai CLI plus its skill and references, the same shim the other
#    platforms get, so `mobai devices` and friends exist here too.
cat > "$BIN/mobai" <<'MOBAI_SHIM'
#!/bin/sh
exec "$HOME/.mobai/bin/mobai-dev" cli "$@"
MOBAI_SHIM
chmod +x "$BIN/mobai"
mkdir -p "$HOME/.agents/skills"
"$BIN/mobai" skills install "$HOME/.agents/skills" >/dev/null 2>&1 \
  || echo "note: could not install the mobai CLI skill" >&2

# 4. The account. Previews are free but not anonymous: the engine is handed
#    its permission to run by mobai-dev, which needs a credential. Codex has a
#    real secrets store, so MOBAI_API_KEY is one way; the other is signing in
#    from the session, which also creates the account when the email is new.
#    Not a failure either way: an agent can sign in when it first needs to.
if [ -z "${MOBAI_API_KEY:-}" ] && ! "$BIN/mobai-dev" login >/dev/null 2>&1; then
  echo "" >&2
  echo "note: no MobAI account on this machine yet. Either add MOBAI_API_KEY to" >&2
  echo "this environment's secrets, or sign in from the session, which also" >&2
  echo "creates the account when the email is new (free):" >&2
  echo "  $BIN/mobai-dev login --email <the user's email>" >&2
  echo "  $BIN/mobai-dev login --email <the user's email> --code <the 6 digits emailed>" >&2
fi

# 5. Runtime helper, the same one every platform gets, served beside this
#    script. The agent runs it in the session; it is safe to run repeatedly.
#    It exits 1 with the two commands when a MobAI sign-in is needed, or
#    when mobai itself failed to come up; it exits 0 once mobai serves, phone
#    or not, and a Tailscale login link the user may approve or skip comes
#    with that 0.
if ! curl -fsSL --retry 3 -o "$BIN/mobai-up" "https://mobai.run/cloud/mobai-up.sh"; then
  echo "could not download mobai-up from mobai.run" >&2
  exit 1
fi
chmod +x "$BIN/mobai-up"

# 6. Agent guidance. Codex reads skills from ~/.agents/skills; per-project
#    preview guidance is installed by `mobai-dev setup --agent codex` inside
#    the repo, which is the first thing an agent should run there.
cat <<'DONE'

installed: mobai-dev, the mobai CLI and its skill, tailscale, and ~/.mobai/bin/mobai-up

In a project, start with:
  ~/.mobai/bin/mobai-dev setup --agent codex --framework <flutter|react-native|swiftui>
It writes .mobai/config.json, prints what this machine still needs, and
installs the previewing-mobile-apps skill that teaches the agent the rest:
previews, mocking, adapters, builds and simulators.

What the agent should know:
- everything needs a MobAI sign-in: MOBAI_API_KEY from the secrets, or
  ~/.mobai/bin/mobai-dev login --email <email> and then --code <emailed code>.
  Free, and it creates the account when the email is new.
- the user's physical iPhone additionally needs the tailnet:
  MOBAI_TAILSCALE_KEY from the secrets, or a Tailscale login link the user
  approves; plus, once per device, the cloud setup in the MobAI desktop app
  (https://mobai.run/download). ~/.mobai/bin/mobai-up does all of this and
  says which human step it is waiting on.
- run ~/.mobai/bin/mobai-up in the session before any device work; this
  setup does not start mobai, because a process started here does not
  survive into the session.
- on Codex the tailnet join fails today: the sandbox blocks the HTTP upgrade
  it needs, and nothing in this setup can change that. mobai-up still brings
  mobai up without the phone. Tell the user; do not keep retrying.
DONE
