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

# mobai cloud session: reach your own iPhone from this agent sandbox.
# Needs two env vars, set in this platform's secret store:
#   MOBAI_API_KEY        your mobai account key
#   MOBAI_TAILSCALE_KEY  an ephemeral Tailscale auth key
# Devices are discovered: mobai asks the API which devices this account
# onboarded, then exposes the ones currently reachable on the tailnet.
set -eu

echo "mobai setup: starts the tailnet and mobai from your stored secrets"

# Report every missing secret at once. Dying on the first one hides the second
# and sends people back for a third round trip.
missing=""
[ -n "${MOBAI_API_KEY:-}" ] || missing="$missing MOBAI_API_KEY"
[ -n "${MOBAI_TAILSCALE_KEY:-}" ] || missing="$missing MOBAI_TAILSCALE_KEY"
if [ -n "$missing" ]; then
  echo "mobai setup needs these environment variables:$missing" >&2
  echo "Add them as secrets for this environment, then start a new session." >&2
  echo "Get them from the cloud setup wizard in the mobai app." >&2
  exit 1
fi

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

# 2. Userspace mode: sandboxes have no TUN device, and usually no outbound UDP,
#    so traffic rides DERP over TCP and the tailnet is reached via SOCKS5.
if ! "$BIN/tailscale" --socket=/tmp/mobai-ts.sock status >/dev/null 2>&1; then
  echo "starting tailscale"
  "$BIN/tailscaled" --tun=userspace-networking \
    --socks5-server=127.0.0.1:1055 \
    --state="$HOME/.mobai/ts.state" --socket=/tmp/mobai-ts.sock \
    >"$HOME/.mobai/tailscaled.log" 2>&1 &
  sleep 2
  # --timeout matters: with a spent or expired key, tailscale up does not fail,
  # it falls back to interactive login and waits forever. In a setup script that
  # is an unattended hang with no output, so bound it and say what to do.
  if ! "$BIN/tailscale" --socket=/tmp/mobai-ts.sock up \
      --authkey="$MOBAI_TAILSCALE_KEY" \
      --timeout=90s \
      --hostname="mobai-agent-$(hostname | tr -cd 'a-z0-9-' | cut -c1-20)"; then
    echo "" >&2
    # A 403 on /machine/register while CONNECT returned 200 is unambiguous: the
    # host is allowed and the method is not. Worth detecting, because the
    # generic advice below sends people to re-check an allowlist that is fine.
    if grep -q "machine/register.*403" "$HOME/.mobai/tailscaled.log" 2>/dev/null; then
      echo "The proxy allowed the connection but refused the request:" >&2
      echo "registration is a POST and it came back 403 Forbidden." >&2
      echo "" >&2
      echo "Fix: in this platform's network settings, allow all HTTP methods." >&2
      echo "Restricting to GET blocks joining a tailnet. The host allowlist is" >&2
      echo "already correct or the connection would not have been made." >&2
    else
      echo "could not join the tailnet. Two different causes look similar here:" >&2
      echo "  - the key was rejected: ephemeral keys are single use and expire," >&2
      echo "    so generate a fresh one and update the secret." >&2
      echo "  - the daemon never reached Running: outbound traffic is blocked." >&2
      echo "    Allow controlplane.tailscale.com and *.tailscale.com." >&2
    fi
    echo "" >&2
    echo "tailscale status:" >&2
    "$BIN/tailscale" --socket=/tmp/mobai-ts.sock status >&2 2>&1 || true
    echo "" >&2
    echo "last lines of tailscaled.log:" >&2
    tail -n 25 "$HOME/.mobai/tailscaled.log" >&2 2>/dev/null || echo "(no log)" >&2
    exit 1
  fi
fi

# 3. Headless mobai. Opens the tunnel to the phone, serves the mobai API and MCP
#    on 127.0.0.1:8686, and registers itself with whichever agent tools are
#    installed here.
if [ ! -x "$BIN/mobai-dev" ]; then
  echo "downloading mobai"
  curl -fsSL -o "$BIN/mobai-dev" \
    "https://github.com/MobAI-App/mobai-dev/releases/download/v$MOBAI_VERSION/mobai-dev_linux_${ARCH}"
  chmod +x "$BIN/mobai-dev"
fi

# 4. The mobai CLI plus its skill and references. MCP is auto-registered here,
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

# Preview support: the same binary previews Flutter/RN/SwiftUI apps with no
# device. There is no per-agent skill installer for this platform yet, so tell
# the human/agent via the setup output; the CLI's own help covers the verbs.
echo "tip: mobai-dev also previews Flutter, React Native and SwiftUI apps"
echo "with no device: run '$BIN/mobai-dev setup --framework <flutter|react-native|swiftui>'"
echo "in the project, then"
echo "'$BIN/mobai-dev preview run --detach' and drive it via 'preview' verbs."

echo "starting mobai"
GOIOS_TUNNEL_SOCKS5=socks5://127.0.0.1:1055 \
  MOBAI_TS_SOCKET=/tmp/mobai-ts.sock \
  "$BIN/mobai-dev" start \
  >"$HOME/.mobai/mobai.log" 2>&1 &

# Wait for a device to actually appear, not just for the API to answer.
#
# Measured on a cold sandbox: the HTTP API binds ~1s after mobai starts, while
# the go-ios tunnel to the phone opens ~65s later, reproducible within 1.5s
# across runs. A 200 with "[]" therefore means nothing, and a 120s budget left
# barely 55s of margin over the real discovery time. 180s is the budget; the
# match is on an actual device id, so an error body cannot pass for a device.
api_answered=0
for _ in $(seq 1 90); do
  devices=$(curl -fsS --max-time 5 http://127.0.0.1:8686/api/v1/devices 2>/dev/null || true)
  if [ -n "$devices" ]; then api_answered=1; fi
  case "$devices" in
    *'"id"'*)
      echo "mobai ready on 127.0.0.1:8686 with a connected device"
      exit 0
      ;;
  esac
  sleep 2
done

# Deliberately exit 0. The message below is addressed to the agent, so the agent
# has to exist to read it: failing environment setup here would leave the user
# with a dead sandbox instead of a working one that says what is missing.
if [ "$api_answered" = "0" ]; then
  echo "mobai never answered on 127.0.0.1:8686 - it is not running." >&2
  echo "AGENT: this is not a device problem. Read $HOME/.mobai/mobai.log, and do" >&2
  echo "not install the desktop app: mobai-dev is what serves this API." >&2
  exit 0
fi
echo "mobai is running but NO DEVICE is connected." >&2
echo "AGENT: do not report this as 'no devices available'. Ask the user to:" >&2
echo "  1. reconnect the iPhone to Wi-Fi, then toggle Tailscale off and on," >&2
echo "  2. open the MobAI app and leave it foregrounded." >&2
echo "The phone can show Online in 'tailscale status' and answer pings while" >&2
echo "still refusing every TCP connection, because the Tailscale network" >&2
echo "extension replies independently of the app. Verify with a TCP connect to" >&2
echo "port 62078 through the SOCKS5 proxy at 127.0.0.1:1055, not with ping." >&2
echo "After the user reconnects, restart mobai-dev (kill its PID and relaunch)" >&2
echo "because the retry backoff grows to 2+ minutes and delays pickup." >&2
exit 0
