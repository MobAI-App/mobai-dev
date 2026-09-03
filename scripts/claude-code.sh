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
  echo "mobai is installed here, two capabilities: (1) preview a Flutter, React Native or SwiftUI app with no device at all - run ~/.mobai/bin/mobai-dev setup --agent claude --framework <flutter|react-native|swiftui> in the project once and follow the previewing-mobile-apps skill it installs; (2) drive the user's own iPhone (screenshots, taps, app install) - run ~/.mobai/bin/mobai-up when they ask for a real-device run. Both need a MobAI sign-in: MOBAI_API_KEY if the environment has it, otherwise an emailed code (free, and it creates the account when the email is new). The phone additionally needs the tailnet: MOBAI_TAILSCALE_KEY if set, otherwise a Tailscale login link the user approves; optional and only for the phone. Prefer the preview for UI iteration; the phone is for verification. Details: mobai-devices skill."
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

mobai serves the user's iPhone over their tailnet. The phone needs two short
approvals from the user: a MobAI sign-in, which every part of mobai needs and
which also creates the account when the email is new, and a Tailscale login,
which is optional and only for the phone. Previews, builds and simulators work
with the sign-in alone.

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
it exits 1 when a MobAI sign-in is needed or mobai failed to start, and 0 once
mobai is serving, with or without the phone (a Tailscale link, when it prints
one, comes with that 0):

1. If it says MobAI sign-in is needed: the account email is usually in
   $MOBAI_ACCOUNT_EMAIL, so use that and do not ask. Only ask the user for it
   when that variable is empty, and tell them signing in also creates their
   free account if they have none. Run the login command it prints, ask for
   the 6-digit code from their inbox, run the second command, then run
   mobai-up again.
2. If it prints a Tailscale login URL: that is optional and only for the
   physical iPhone. Say so. If the user wants the phone, show them the link,
   wait for them to say they approved it, then run mobai-up again. If they do
   not, carry on: previews, builds and simulators are all available.
3. Done when it prints: mobai ready on 127.0.0.1:8686. It does not wait for
   the phone: with the tailnet up, the iPhone appears in `mobai devices`
   within about a minute of starting, if it is awake and reachable. "No
   phone" means the tailnet is not up, and the output says what the user
   would have to do: be on the same Tailscale account and network as the
   agent, and, once per device, run the cloud setup in the MobAI desktop app
   (https://mobai.run/download).

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
