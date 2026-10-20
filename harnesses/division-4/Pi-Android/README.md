# Pi on Termux (native Android, no proot)

**Verdict:** NATIVE · **Confidence:** high — device-verified 2026-10-20 (install, CLI smoke, and a full agent turn against an OpenAI-compatible endpoint via a `models.json` custom provider)

## TL;DR

```bash
npm install -g @earendil-works/pi-coding-agent
```

## What it is

Pi is a coding-agent CLI ("read, bash, edit, write tools and session management") by Mario Zechner, part of the `earendil-works/pi` monorepo ("AI agent toolkit: unified LLM API, agent loop, TUI, coding agent CLI"). MIT-licensed. It is a pure Node.js ESM app — shebang `#!/usr/bin/env node`, no binary shim — so it runs directly on Termux's native Node with zero patches. Proven on-device: `pi --version` → `0.84.1` (autopsy 2026-10-20).

## One-command install

The TL;DR command is the whole install. Termux's `nodejs` package is the only prerequisite, and it lands `pi` on your PATH via `$PREFIX/bin/pi → ../lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js`. No script needed — that is why this harness has no `install.sh`.

## Step-by-step

```bash
pkg install -y nodejs   # if you don't already have it
npm install -g @earendil-works/pi-coding-agent
pi --version
pi                      # start a session in the cwd
```

## Termux quirks & workarounds

- Phantom killer: N/A — JavaScript on Termux's native Node.
- TMPDIR/seccomp: nothing special; Node handles Android fine on Termux.
- The `#!/usr/bin/env node` shebang works because Termux provides `/usr/bin/env` inside `$PREFIX`. Do not copy the `pi` symlink into a bare-Android PATH without `$PREFIX/bin` — it stops resolving.
- Auth: provider API keys via env / `pi` config — copy-paste friendly, no desktop-browser callback.
- If a *future* version grows a native-addon sub-dep and install fails, `npm install -g --ignore-scripts @earendil-works/pi-coding-agent` usually suffices for JS-only CLIs (not needed for 0.84.1).

## Limits

- Needs a network connection and at least one model-provider API key — it's a harness, not a local model.
- As with any npm global, a Termux `nodejs` major upgrade can require a reinstall (`npm install -g` again) if native deps ever appear.

## Sources

- https://github.com/earendil-works/pi (verified via GitHub API 2026-10-20)
- npm: `@earendil-works/pi-coding-agent@0.84.1` (verified installed on-device 2026-10-20)
