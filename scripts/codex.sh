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

# 5. Runtime helper, the same one every platform gets, written here from
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
