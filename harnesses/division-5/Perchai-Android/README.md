# Perchai on Termux (native Android, no proot)
**Verdict:** NATIVE · **Confidence:** high — device-verified 2026-10-20 (npm install clean; `perch --version`/`--help` ran)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-5/Perchai-Android/install.sh | bash
```

## What it is
"Perchai" is the **Perch AI** CLI (perchai.app) — the terminal client of a hosted "team of agents" product (web, desktop, terminal and phone PWA). Per the vendor docs it "runs the same agentic loop and citation engine as the desktop app": interactive chat in a folder, one-shot `perch run`, MCP connections, BYOK/BYOLM modes. Ships on npm as `perchai-cli@2.4.112` (bin `perch`, Node 18+). ⚠️ Single-vendor lineage: perchai.app and the npm package have the same operator; the only independent confirmation is the registry entry.

## One-command install
The TL;DR script pins the checked version (`2.4.112`, override with `PERCHAI_VERSION=`) and tries the plain install. If a future `@napi-rs/canvas` release breaks it, the script retries with `--omit=optional`, then `--ignore-scripts`. Today the plain install works: `npm install -g perchai-cli@2.4.112`.

## Step-by-step
```bash
pkg install -y nodejs                  # Node 18+ required; Termux ships well past that
npm install -g perchai-cli@2.4.112     # or use install.sh for the fallback chain
perch login                            # opens a browser tab on-device, saves the session
perch                                  # interactive session in the cwd
```

## Termux quirks & workarounds
- npm package name = **`perchai-cli`**, command = **`perch`** (not `perchai`).
- `@napi-rs/canvas` resolves its `canvas-android-arm64` prebuild on-device — plain `npm install -g` landed clean, no `--force` needed (checked 2026-10-20).
- `perch login` is phone-friendly: the browser opens on the same device and the token saves locally.
- Phantom process killer (~32 child processes, device-wide): use `tmux` and disable child-process restrictions in Developer Options.

## Limits
- Device-verified to `--version`/`--help`. A logged-in agent session was not tested.
- Hosted product: the agent loop runs on Perch AI's backend and needs an account.
- No published npm checksums; pinned by version only.

## Sources
- https://www.perchai.app/cli (install + login, Node 18+)
- https://www.perchai.app/docs/using-perch/cli (subcommands, MCP, BYOK/BYOLM)
- npm registry `perchai-cli` (checked 2026-10-20, incl. `canvas-android-arm64` resolution)
- Device verification 2026-10-20 (aarch64 Android phone): `perch --version` / `--help`
