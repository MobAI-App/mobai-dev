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

# 4. Runtime helper, the same one every platform gets, written here from
#    the same block in every setup script. The agent runs it in the session;
#    it is safe to run repeatedly.
#    It exits 1 with the two commands when a MobAI sign-in is needed, or
#    when mobai itself failed to come up; it exits 0 once mobai serves, phone
#    or not, and a Tailscale login link the user may approve or skip comes
#    with that 0.
# The block below is byte-identical in claude-code.sh, cursor.sh and
# codex.sh; change it in all three or in none.
cat > "$BIN/mobai-up" <<'MOBAI_UP'
#!/bin/sh
# mobai-up: bring mobai up for this agent session. Written by every
# platform's setup script as ~/.mobai/bin/mobai-up, from a block that is
# byte-identical across them, so all of them run the same logic:
#
#   1. MobAI account: MOBAI_API_KEY from the environment if set, otherwise the
#      stored login; with neither, the agent signs in (an emailed 6-digit
#      code), which also creates the account when the email is new.
#   2. Tailnet, only for the user's physical iPhone and never fatal:
#      MOBAI_TAILSCALE_KEY if set, otherwise a login link the user approves.
#      Some sandboxes (Codex, as of this writing) block the connection a join
#      needs; mobai still comes up, without the phone.
#   3. mobai itself, whatever the tailnet did.
#
# Safe to run repeatedly. Exit 1 means a human step is needed and the output
# says which; exit 0 means mobai is serving, with or without a phone.
set -eu
BIN="$HOME/.mobai/bin"
STATE="$HOME/.mobai"
# Logs and state hold a login URL and the node's identity; nobody else on the
# box needs to read them.
umask 077

# alive <pidfile>: whether the process recorded there is still running. PID
# files rather than pgrep: pgrep is not POSIX and is missing from some
# sandboxes, and matching command lines can hit the agent's own shell.
alive() { [ -f "$1" ] && kill -0 "$(cat "$1")" 2>/dev/null; }

start_tailscaled() {
  # --statedir: where tailscaled keeps the TLS certificate that
  # `tailscale serve` (mobai-dev ota) needs; with only a --state file it
  # fails with "no TailscaleVarRoot".
  mkdir -p "$STATE/ts-var"
  nohup "$BIN/tailscaled" --tun=userspace-networking \
    --socks5-server=127.0.0.1:1055 \
    --state="$STATE/ts.state" --statedir="$STATE/ts-var" \
    --socket=/tmp/mobai-ts.sock \
    </dev/null >"$STATE/tailscaled.log" 2>&1 &
  echo $! > "$STATE/tailscaled.pid"
  sleep 2
}

# 1. The MobAI account, first: it is what previews, builds and the phone all
#    need, and signing in also creates the account when the email is new.
if [ -z "${MOBAI_API_KEY:-}" ] && ! "$BIN/mobai-dev" login >/dev/null 2>&1; then
  echo "MobAI sign-in needed. It is free and also creates the account if the"
  echo "email is new. Ask the user for their email, then run:"
  echo "  $BIN/mobai-dev login --email <email>"
  echo "then, with the 6-digit code from that inbox:"
  echo "  $BIN/mobai-dev login --email <email> --code <code>"
  echo "and run this script again."
  exit 1
fi

# 2. The tailnet, only for the user's physical iPhone. Optional: previews,
#    builds and simulators need none of it, so nothing here stops the session.
#    With MOBAI_TAILSCALE_KEY set the join is silent; without it, the user
#    approves a login link once per session.
TS_STATE=down
tailnet_up() { "$BIN/tailscale" --socket=/tmp/mobai-ts.sock status >/dev/null 2>&1; }
if [ -x "$BIN/tailscaled" ] && [ "${MOBAI_SKIP_TAILSCALE:-0}" != "1" ]; then
  if tailnet_up; then
    TS_STATE=up
  else
    alive "$STATE/tailscaled.pid" || start_tailscaled
    UP_LOG="$STATE/ts-up.log"

    # A consumed auth path poisons the state. The browser login completes the
    # node's registration, which retires that one-time auth path; the
    # backgrounded "up" is still polling it and gets HTTP 410 "auth path not
    # found", then retries forever. The state file keeps handing back the same
    # dead URL, so re-running this prints the link the user already approved
    # and nothing ever works. Only a fresh identity clears it.
    #
    # Either log can carry it: the daemon's, or the backgrounded up's. Kill
    # by PID file, never "pkill -f ...mobai-ts.sock": that pattern matches
    # the agent's own shell command line and kills the shell mid-script.
    if grep -q "auth path not found" "$STATE/tailscaled.log" "$UP_LOG" 2>/dev/null; then
      echo "The previous Tailscale login was already used up, so this node could" >&2
      echo "never finish joining. Resetting it and getting a fresh link." >&2
      for f in "$STATE/ts-up.pid" "$STATE/tailscaled.pid"; do
        if alive "$f"; then kill "$(cat "$f")" 2>/dev/null || true; fi
        rm -f "$f"
      done
      sleep 1
      rm -f "$STATE/ts.state" /tmp/mobai-ts.sock "$STATE/tailscaled.log" "$UP_LOG"
      start_tailscaled
    fi

    HOSTNAME_ARG="--hostname=mobai-agent-$(hostname | tr -cd 'a-z0-9-' | cut -c1-20)"
    if [ -n "${MOBAI_TAILSCALE_KEY:-}" ]; then
      # --timeout matters: with a spent or expired key, tailscale up does not
      # fail, it falls back to interactive login and waits forever.
      if "$BIN/tailscale" --socket=/tmp/mobai-ts.sock up \
          --authkey="$MOBAI_TAILSCALE_KEY" --timeout=90s "$HOSTNAME_ARG" \
          >"$UP_LOG" 2>&1; then
        TS_STATE=up
      else
        TS_STATE=failed
        echo "note: could not join the tailnet with MOBAI_TAILSCALE_KEY. Ephemeral" >&2
        echo "keys are single use and expire; egress to *.tailscale.com must be" >&2
        echo "allowed; and some sandboxes (Codex, at the time of writing) block the" >&2
        echo "HTTP upgrade a join needs, which nothing on this side can fix. See" >&2
        echo "$UP_LOG. Previews, builds and simulators are unaffected." >&2
      fi
    else
      # An agent's shell only shows output when a command ENDS, so "tailscale
      # up" must not block here waiting for approval: run it in the background,
      # pull the URL out of its log, and carry on. The backgrounded up finishes
      # the join on its own the moment the user approves.
      if ! alive "$STATE/ts-up.pid"; then
        nohup "$BIN/tailscale" --socket=/tmp/mobai-ts.sock up "$HOSTNAME_ARG" \
          </dev/null >"$UP_LOG" 2>&1 &
        echo $! > "$STATE/ts-up.pid"
      fi
      i=0
      while [ $i -lt 20 ]; do
        if tailnet_up; then TS_STATE=up; break; fi
        if grep -o 'https://login\.tailscale\.com/[A-Za-z0-9/_-]*' "$UP_LOG" >/dev/null 2>&1; then
          TS_STATE=pending
          TS_URL=$(grep -o 'https://login\.tailscale\.com/[A-Za-z0-9/_-]*' "$UP_LOG" | head -1)
          break
        fi
        i=$((i+1)); sleep 1
      done
      # No link and no node: the control connection itself is being refused,
      # which is the sandbox's egress (a 403 on the upgrade), not the user.
      if [ "$TS_STATE" = down ] && grep -qiE "upgrade.*403|403.*upgrade|proxy.*403" "$STATE/tailscaled.log" "$UP_LOG" 2>/dev/null; then
        TS_STATE=failed
        echo "note: the tailnet control connection was refused by this sandbox's" >&2
        echo "proxy (Codex does this today: it blocks the HTTP upgrade a join needs)." >&2
        echo "See $STATE/tailscaled.log. Previews, builds and simulators are" >&2
        echo "unaffected." >&2
      fi
    fi
  fi
fi

# 3. mobai itself, whatever the tailnet did: the phone appears when it is
#    reachable, and everything else works now.
if ! curl -fsS -o /dev/null http://127.0.0.1:8686/api/v1/devices 2>/dev/null; then
  GOIOS_TUNNEL_SOCKS5=socks5://127.0.0.1:1055 \
  MOBAI_TS_SOCKET=/tmp/mobai-ts.sock \
    nohup "$BIN/mobai-dev" start </dev/null >"$STATE/mobai.log" 2>&1 &
  echo $! > "$STATE/mobai.pid"
  i=0
  while [ $i -lt 60 ]; do
    if curl -fsS -o /dev/null http://127.0.0.1:8686/api/v1/devices 2>/dev/null; then
      break
    fi
    # A rejected key or an expired login ends the process at once; no point
    # waiting two minutes for a port that will never open.
    alive "$STATE/mobai.pid" || break
    i=$((i+1)); sleep 2
  done
fi

if ! curl -fsS -o /dev/null http://127.0.0.1:8686/api/v1/devices 2>/dev/null; then
  echo "mobai did not become ready; see $STATE/mobai.log:" >&2
  tail -n 5 "$STATE/mobai.log" >&2 2>/dev/null || true
  echo "AGENT: this is not a device problem. Read that log, and do not install" >&2
  echo "the desktop app: mobai-dev is what serves this API." >&2
  exit 1
fi

phone_note() {
  echo "To use the user's physical iPhone from here, they need to:"
  echo "  1. sign in to Tailscale for this session (the link above, when shown),"
  echo "  2. have the iPhone on that same Tailscale account and network,"
  echo "  3. once per device, run the cloud setup in the MobAI desktop app"
  echo "     (https://mobai.run/download): it pairs the phone for cloud access."
  echo "Previews, builds and simulators work without any of this."
}

case "$TS_STATE" in
  pending)
    echo "mobai ready on 127.0.0.1:8686 (no phone yet)."
    echo "Optional, only if the user wants their physical iPhone: have them open"
    echo "  $TS_URL"
    echo "and approve it, then run this script again."
    phone_note
    exit 0
    ;;
  down)
    echo "mobai ready on 127.0.0.1:8686 (no phone: the tailnet is not up)."
    phone_note
    exit 0
    ;;
  failed)
    echo "mobai ready on 127.0.0.1:8686 (no phone: the tailnet join failed, see above)."
    echo "AGENT: if this sandbox blocks the join (Codex does today), say so to the"
    echo "user rather than retrying; it is the platform's egress, not their setup."
    phone_note
    exit 0
    ;;
esac

# The tailnet is up. The phone, when it is reachable, appears in the device
# list on its own: the tunnel to it opens about a minute after mobai starts,
# so an empty list right now means nothing yet. No waiting here; the agent
# asks `mobai devices` when it needs the phone.
echo "mobai ready on 127.0.0.1:8686; the tailnet is up."
echo "The user's iPhone appears in 'mobai devices' within about a minute of"
echo "starting, if it is awake, on the same Tailscale account and network, and"
echo "was set up for cloud access once in the MobAI desktop app."
echo "If it never appears: have the user reconnect it to Wi-Fi, toggle Tailscale"
echo "off and on, and leave the MobAI app foregrounded. The phone can show Online"
echo "in 'tailscale status' and answer pings while still refusing every TCP"
echo "connection, because the Tailscale network extension replies independently"
echo "of the app. After they reconnect the phone is retried within a minute;"
echo "$STATE/mobai.log says which peers were found, what failed and when it"
echo "retries. To put a build on the phone without the bridge: mobai-dev ota."
exit 0
MOBAI_UP
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
