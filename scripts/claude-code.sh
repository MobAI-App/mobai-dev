#!/bin/sh
# MobAI cloud-agent setup for Claude Code sandboxes.
#
# Served from https://mobai.run/cloud/claude-code.sh so it can be fixed without
# anyone re-pasting it into their environment settings. What users paste is the
# one-liner that fetches this file.
#
# The version is pinned rather than resolved from "latest": resolving is a
# server-side redirect some sandboxes refuse (Codex returns 403 for it), while a
# plain asset download works everywhere. Bump this on every release.
MOBAI_VERSION=1.0.0

# mobai for Claude Code web: installs tools only, no credentials involved.
# Connecting happens later, inside the chat, where you approve a Tailscale
# login link and an emailed code. Nothing here reads any secret.
set -eu

echo "mobai setup: Claude Code (installs tools only, you connect in the chat)"

# Pasted into the wrong platform? Codex and Cursor need the other script, the
# one that joins the tailnet and starts mobai. Their secrets being present is
# the giveaway, and silently doing nothing is worse than saying so.
if [ -n "${MOBAI_TAILSCALE_KEY:-}" ] || [ -n "${MOBAI_API_KEY:-}" ]; then
  echo "" >&2
  echo "This is the Claude Code script, but MOBAI_TAILSCALE_KEY/MOBAI_API_KEY are set," >&2
  echo "which means you are probably on Codex or Cursor. Copy the script from that" >&2
  echo "tab in the mobai cloud wizard instead: this one never starts mobai." >&2
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

# 2. Headless mobai.
if [ ! -x "$BIN/mobai-dev" ]; then
  echo "downloading mobai"
  curl -fsSL -o "$BIN/mobai-dev" \
    "https://github.com/MobAI-App/mobai-dev/releases/download/v$MOBAI_VERSION/mobai-dev_linux_${ARCH}"
  chmod +x "$BIN/mobai-dev"
fi

# 3. The mobai CLI plus its skill and references. The CLI is inside the binary
#    downloaded above, so this is a two-line shim rather than an npm install:
#    no package manager to depend on, and the CLI and its skills are always the
#    same version as mobai-dev instead of whatever npm last published.
cat > "$BIN/mobai" <<'MOBAI_SHIM'
#!/bin/sh
exec "$HOME/.mobai/bin/mobai-dev" cli "$@"
MOBAI_SHIM
chmod +x "$BIN/mobai"

# The skill also brings the DSL and .mob references to disk, which is how an
# agent reads the full action surface where no MCP resources are served.
mkdir -p "$HOME/.claude/skills"
"$BIN/mobai" skills install "$HOME/.claude/skills" >/dev/null 2>&1 \
  || echo "note: could not install the mobai CLI skill" >&2

# 4. Runtime helper. The agent runs this in the session; it is safe to run
#    repeatedly and stops with instructions when a human step is needed.
cat > "$BIN/mobai-up" <<'MOBAI_UP'
#!/bin/sh
# Bring up the tailnet and mobai for this session.
set -eu
BIN="$HOME/.mobai/bin"

if ! "$BIN/tailscale" --socket=/tmp/mobai-ts.sock status >/dev/null 2>&1; then
  if ! pgrep -f "tailscaled.*mobai-ts.sock" >/dev/null 2>&1; then
    "$BIN/tailscaled" --tun=userspace-networking \
      --socks5-server=127.0.0.1:1055 \
      --state="$HOME/.mobai/ts.state" --socket=/tmp/mobai-ts.sock \
      >"$HOME/.mobai/tailscaled.log" 2>&1 &
    sleep 2
  fi

  # No auth key on this platform: the user approves a login link instead. An
  # agent's shell only shows output when a command ENDS, so "tailscale up" must
  # not block here waiting for approval - run it in the background, pull the
  # URL out of its log, and exit. The backgrounded up finishes the join on its
  # own the moment the user approves; the next run of this script sails through.
  UP_LOG="$HOME/.mobai/ts-up.log"

  # A consumed auth path poisons the state. The browser login completes the
  # node's registration, which retires that one-time auth path; the backgrounded
  # "up" is still polling it and gets HTTP 410 "auth path not found", then
  # retries forever. The state file keeps handing back the same dead URL, so
  # re-running this prints the link the user already approved and nothing ever
  # works. Only a fresh identity clears it.
  #
  # Kill by PID, never "pkill -f ...mobai-ts.sock": that pattern matches the
  # agent's own shell command line and kills the shell mid-script.
  if grep -q "auth path not found" "$HOME/.mobai/tailscaled.log" 2>/dev/null; then
    echo "The previous Tailscale login was already used up, so this node could" >&2
    echo "never finish joining. Resetting it and getting a fresh link." >&2
    for pid in $(pgrep -f "tailscaled.*mobai-ts.sock" 2>/dev/null); do
      kill "$pid" 2>/dev/null || true
    done
    rm -f "$HOME/.mobai/ts.state" /tmp/mobai-ts.sock \
      "$HOME/.mobai/tailscaled.log" "$UP_LOG"
    sleep 1
    "$BIN/tailscaled" --tun=userspace-networking --socks5-server=127.0.0.1:1055 \
      --state="$HOME/.mobai/ts.state" --socket=/tmp/mobai-ts.sock \
      >"$HOME/.mobai/tailscaled.log" 2>&1 &
    sleep 2
  fi

  if ! pgrep -f "tailscale.*mobai-ts.sock up" >/dev/null 2>&1; then
    "$BIN/tailscale" --socket=/tmp/mobai-ts.sock up \
      --hostname="mobai-agent-$(hostname | tr -cd 'a-z0-9-' | cut -c1-20)" \
      >"$UP_LOG" 2>&1 &
  fi

  i=0
  while [ $i -lt 20 ]; do
    if "$BIN/tailscale" --socket=/tmp/mobai-ts.sock status >/dev/null 2>&1; then
      break
    fi
    if grep -o 'https://login\.tailscale\.com/[A-Za-z0-9/_-]*' "$UP_LOG" >/dev/null 2>&1; then
      echo "Tailscale needs the user's approval. Have them open:"
      grep -o 'https://login\.tailscale\.com/[A-Za-z0-9/_-]*' "$UP_LOG" | head -1
      echo "then run this script again."
      echo "If that link comes back unchanged after they approved it, the login"
      echo "was consumed: re-run this script and it resets the node itself."
      exit 1
    fi
    i=$((i+1)); sleep 1
  done

  if ! "$BIN/tailscale" --socket=/tmp/mobai-ts.sock status >/dev/null 2>&1; then
    echo "tailscale did not come up; see $UP_LOG and $HOME/.mobai/tailscaled.log" >&2
    exit 1
  fi
fi

if ! "$BIN/mobai-dev" login >/dev/null 2>&1; then
  echo "mobai login needed. Run:"
  echo "  $BIN/mobai-dev login --email <account email>"
  echo "then, with the 6-digit code from that inbox:"
  echo "  $BIN/mobai-dev login --email <account email> --code <code>"
  echo "and run this script again."
  exit 1
fi

if ! curl -fsS -o /dev/null http://127.0.0.1:8686/api/v1/devices 2>/dev/null; then
  GOIOS_TUNNEL_SOCKS5=socks5://127.0.0.1:1055 \
  MOBAI_TS_SOCKET=/tmp/mobai-ts.sock \
    "$BIN/mobai-dev" start >"$HOME/.mobai/mobai.log" 2>&1 &
  i=0
  while [ $i -lt 60 ]; do
    if curl -fsS -o /dev/null http://127.0.0.1:8686/api/v1/devices 2>/dev/null; then
      break
    fi
    i=$((i+1)); sleep 2
  done
fi

if ! curl -fsS -o /dev/null http://127.0.0.1:8686/api/v1/devices 2>/dev/null; then
  echo "mobai did not become ready; see $HOME/.mobai/mobai.log" >&2
  exit 1
fi

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
MOBAI_UP
chmod +x "$BIN/mobai-up"

# 5. SessionStart hook: its stdout lands in the agent's context when a session
#    starts, so the agent knows mobai is here without the user pasting anything.
#    Kept fast and read-only; the actual bring-up stays in mobai-up.
cat > "$BIN/mobai-hook" <<'MOBAI_HOOK'
#!/bin/sh
devs=$(curl -fsS http://127.0.0.1:8686/api/v1/devices 2>/dev/null || echo "")
if [ -n "$devs" ] && [ "$devs" != "[]" ]; then
  echo "mobai is running on 127.0.0.1:8686 with a connected device: drive it via the mobai MCP tools or GET http://127.0.0.1:8686/api/v1/devices. For UI iteration on a Flutter, React Native or SwiftUI app, prefer the device-free preview: run ~/.mobai/bin/mobai-dev setup --agent claude --framework <flutter|react-native|swiftui> in the project once, then follow the previewing-mobile-apps skill it installs."
elif [ -n "$devs" ]; then
  echo "mobai is running on 127.0.0.1:8686 but no device is connected. This is not 'no devices available' - the user's iPhone is simply not reachable yet. Ask them to reconnect it to Wi-Fi, toggle Tailscale off and on, and leave the MobAI app foregrounded, then run ~/.mobai/bin/mobai-up. Meanwhile nothing blocks UI work: the preview needs no device. Run ~/.mobai/bin/mobai-dev setup --agent claude --framework <flutter|react-native|swiftui> in the project and follow the previewing-mobile-apps skill it installs."
else
  echo "mobai is installed here, two capabilities: (1) preview a Flutter, React Native or SwiftUI app with no device at all - run ~/.mobai/bin/mobai-dev setup --agent claude --framework <flutter|react-native|swiftui> in the project once and follow the previewing-mobile-apps skill it installs; (2) drive the user's own iPhone (screenshots, taps, app install) - run ~/.mobai/bin/mobai-up when they ask for a real-device run; it needs them to approve a Tailscale link and an emailed code. Prefer the preview for UI iteration; the phone is for verification. Details: mobai-devices skill."
fi
exit 0
MOBAI_HOOK
chmod +x "$BIN/mobai-hook"

SETTINGS="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"
if [ -f "$SETTINGS" ] && command -v python3 >/dev/null 2>&1; then
  # Merge, never clobber: the sandbox may have its own settings already.
  python3 - "$SETTINGS" "$BIN/mobai-hook" <<'MOBAI_PY'
import json, sys
path, cmd = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
hooks = data.setdefault("hooks", {}).setdefault("SessionStart", [])
if not any(h.get("command") == cmd for e in hooks for h in e.get("hooks", [])):
    hooks.append({"hooks": [{"type": "command", "command": cmd}]})
with open(path, "w") as f:
    json.dump(data, f, indent=2)
MOBAI_PY
elif [ ! -f "$SETTINGS" ]; then
  cat > "$SETTINGS" <<MOBAI_JSON
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "$BIN/mobai-hook" }] }
    ]
  }
}
MOBAI_JSON
else
  echo "note: $SETTINGS exists and python3 is missing; add a SessionStart hook for $BIN/mobai-hook yourself" >&2
fi

# 6. Skill: how to bring mobai up and use it, so the agent does not have to be
#    told in every conversation.
SKILL_DIR="$HOME/.claude/skills/mobai-devices"
mkdir -p "$SKILL_DIR"
cat > "$SKILL_DIR/SKILL.md" <<'MOBAI_SKILL'
---
name: mobai-devices
description: Drive the user's own iPhone from this sandbox - screenshots, taps, app install, UI tests on a real device. Use when asked to run, test, or debug an iOS app on a device.
---

# Real iPhone from this sandbox

mobai serves the user's iPhone over their tailnet. Nothing device-side works
until it is up, and bringing it up needs two short approvals from the user.

## Prefer the preview for UI work

Most iteration does not need the phone. The same mobai-dev binary previews
Flutter, React Native and SwiftUI apps in a phone sized viewport right here,
with no device, no approvals and no waiting: semantic tree, taps, typing,
screenshots, hot reload, mocked location/permissions/network. Set it up once
per project:

    ~/.mobai/bin/mobai-dev setup --agent claude --framework <flutter|react-native|swiftui>

and follow the previewing-mobile-apps skill it installs into the project.
Engine downloads work from this sandbox (release asset downloads are allowed).
Reach for the real iPhone below when the question is native behaviour,
performance, or final verification.

## Bring it up

Run ~/.mobai/bin/mobai-up and follow its output. It is safe to run repeatedly;
it exits with instructions whenever a human step is needed:

1. If it prints a Tailscale login URL: show it to the user, wait for them to
   say they approved it, then run mobai-up again.
2. If it says login is needed: the account email is usually in
   $MOBAI_ACCOUNT_EMAIL, so use that and do not ask. Only ask the user for it
   when that variable is empty. Run the login command it prints, ask for the
   6-digit code from their inbox, run the second command, then run mobai-up
   again.
3. Done when it prints: mobai ready on 127.0.0.1:8686

## Control devices

Use the `mobai` CLI at ~/.mobai/bin/mobai (it is the same binary as
mobai-dev, so there is nothing else to install). It already points at the
local server, so no URL or device id is needed for a single connected phone.

    mobai devices                     # list, and confirm bridgeRunning
    mobai bridge start                # needed once before UI control
    mobai observe                     # UI tree, to pick selectors
    mobai screenshot --path /tmp

Write ~/.mobai/bin/mobai in full, or put ~/.mobai/bin on PATH first.

When you already know the sequence, batch it into ONE call instead of chaining
single commands - fewer round trips, and per-step results that name the step
that failed:

    mobai dsl '{"version":"0.2","steps":[
      {"action":"open_app","bundle_id":"com.example.app"},
      {"action":"tap","predicate":{"text":"Sign in"}},
      {"action":"assert","predicate":{"text_contains":"Welcome"}}
    ]}'

The full action surface, predicates and failure strategies are in the
using-mobai-cli skill installed alongside this one, including its
references/device-automation.md. Read that before anything the example above
does not make obvious.

Do NOT try to register a mobai MCP server here; this platform does not allow
third-party MCP. The CLI is the supported path. The raw HTTP API on
http://127.0.0.1:8686/api/v1 is a fallback if the CLI is unavailable.

A device can be legitimately absent: if the phone is asleep or off the
tailnet, the list is empty. Tell the user to wake the phone rather than
treating it as an error.

## Build the app

This sandbox has no Xcode, so an .ipa has to be built by CI on a macOS runner.

The GitHub API is blocked here, so do NOT try to trigger a build or fetch
artifacts through it, and do not try to install a CLI that does. Both fail with
403 no matter how they authenticate. Only two things reach GitHub from this
sandbox: git through the configured remote, and release asset downloads.

So the build loop is:

1. Check the repo for an iOS build workflow under .github/workflows. If there is
   none, stop: it is a one-time setup the user does on their own machine, and
   the mobai cloud wizard has the instructions. You cannot add it from here.
2. Commit and push. The workflow triggers on push.
3. The workflow publishes the .ipa as a release asset. Poll for it, since you
   cannot read build status from here:
   curl -fsSL -o /tmp/app.ipa \
     https://github.com/OWNER/REPO/releases/download/TAG/APP.ipa
   Expect a few minutes. A 404 means it is not built yet; keep waiting.
4. Install it with: mobai app install /tmp/app.ipa

If the workflow uploads a plain Actions artifact instead of a release asset, it
cannot be fetched from here at all. Tell the user it needs to publish a release
asset instead.

## Sign and install

An unsigned .ipa will not install on a physical device.

- If signing artifacts are configured for this session (the user set
  MOBAI_SIGN_PROFILE_B64 plus either MOBAI_SIGN_P12_B64/MOBAI_SIGN_P12_PASSWORD
  or MOBAI_SIGN_CERT_B64/MOBAI_SIGN_KEY_B64), sign with:
  POST http://127.0.0.1:8686/api/v1/devices/{id}/sign/offline
  with JSON body {"path": "/absolute/path/to/app.ipa"} - the artifacts are
  picked up from the environment automatically. Then install the output with
  install_app.
- Never print, echo, or log the values of MOBAI_SIGN_* variables.
- On Claude Code web there is currently no safe place for those variables, so
  signing is usually unavailable here: build unsigned, and tell the user to
  sign and install from a machine that has the artifacts, or Builder's own
  signing on the runner.
MOBAI_SKILL

echo "installed: tailscale, mobai, the session hook, and the mobai-devices skill"
echo "in a session, just ask the agent to run something on your device"
