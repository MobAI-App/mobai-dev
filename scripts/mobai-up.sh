#!/bin/sh
# mobai-up: bring mobai up for this agent session. Served from
# https://mobai.run/cloud/mobai-up.sh and installed by every platform's setup
# script as ~/.mobai/bin/mobai-up, so all of them run the same logic:
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
  nohup "$BIN/tailscaled" --tun=userspace-networking \
    --socks5-server=127.0.0.1:1055 \
    --state="$STATE/ts.state" --socket=/tmp/mobai-ts.sock \
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
echo "of the app. After they reconnect, restart mobai-dev (kill its PID and"
echo "relaunch): the retry backoff grows to 2+ minutes and delays pickup."
exit 0
