#!/bin/sh
# MobAI cloud-agent setup for cursor sandboxes.
#
# Served from https://mobai.run/cloud/cursor.sh so it can be fixed without
# anyone re-pasting it into their environment settings. What users paste is the
# one-liner that fetches this file.
#
# The version is pinned rather than resolved from "latest": resolving is a
# server-side redirect some sandboxes refuse (Codex returns 403 for it), while a
# plain asset download works everywhere. Bump this on every release.
MOBAI_VERSION=1.0.0

# mobai cloud session: previews, builds and, when the user wants it, their own
# iPhone from this agent sandbox. Nothing here is required up front:
#   MOBAI_API_KEY        the account key; without it the agent signs in from
#                        the session with an emailed code, which also creates
#                        the account when the email is new
#   MOBAI_TAILSCALE_KEY  an ephemeral Tailscale auth key, only for the phone;
#                        without it the tailnet is joined by a login link the
#                        user approves, or not at all
# Devices are discovered: mobai asks the API which devices this account
# onboarded, then exposes the ones currently reachable on the tailnet.
set -eu

echo "mobai setup: installs mobai-dev and tailscale, then brings mobai up"

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

# 2. Headless mobai. Opens the tunnel to the phone, serves the mobai API and MCP
#    on 127.0.0.1:8686, and registers itself with whichever agent tools are
#    installed here.
if [ ! -x "$BIN/mobai-dev" ]; then
  echo "downloading mobai"
  curl -fsSL -o "$BIN/mobai-dev" \
    "https://github.com/MobAI-App/mobai-dev/releases/download/v$MOBAI_VERSION/mobai-dev_linux_${ARCH}"
  chmod +x "$BIN/mobai-dev"
fi

# 3. The mobai CLI plus its skill and references. MCP is auto-registered here,
#    but 'mobai dsl' still batches whole flows into one call. The CLI is inside
#    the binary downloaded above, so this is a two-line shim rather than an npm
#    install: no package manager to depend on, and the CLI and its skills are
#    always the same version as mobai-dev instead of whatever npm last
#    published.
cat > "$BIN/mobai" <<'MOBAI_SHIM'
#!/bin/sh
exec "$HOME/.mobai/bin/mobai-dev" cli "$@"
MOBAI_SHIM
chmod +x "$BIN/mobai"

# The skill also brings the DSL and .mob references to disk, which is how an
# agent reads the full action surface where no MCP resources are served.
mkdir -p "$HOME/.cursor/skills"
"$BIN/mobai" skills install "$HOME/.cursor/skills" >/dev/null 2>&1 \
  || echo "note: could not install the mobai CLI skill" >&2

# 4. Runtime helper, the same one every platform gets, served beside this
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

cat <<'DONE'

installed: mobai-dev, the mobai CLI and its skill, tailscale

What the agent should know:
- previews of Flutter, React Native and SwiftUI apps need no device: run
  ~/.mobai/bin/mobai-dev setup --framework <flutter|react-native|swiftui> in
  the project, then follow the previewing-mobile-apps skill it installs.
- everything needs a MobAI sign-in: MOBAI_API_KEY, or
  ~/.mobai/bin/mobai-dev login --email <email> and then --code <emailed code>.
  Free, and it creates the account when the email is new.
- the user's physical iPhone additionally needs the tailnet: MOBAI_TAILSCALE_KEY,
  or a Tailscale login link the user approves; plus, once per device, the
  cloud setup in the MobAI desktop app (https://mobai.run/download).
DONE

echo "bringing mobai up"
"$BIN/mobai-up" || true
