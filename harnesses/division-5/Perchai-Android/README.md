# Perchai on Termux (native Android, no proot)

**Verdict:** NATIVE · **Confidence:** high — device-verified 2026-10-20 (npm install clean; `perch --version`/`--help` ran)

## TL;DR

```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-5/Perchai-Android/install.sh | bash
```

## What it is

"Perchai" is the **Perch AI** CLI (perchai.app) — the terminal client of a hosted "team of agents" product (web + desktop + terminal + phone PWA). Per the vendor docs it "runs the same agentic loop and citation engine as the desktop app": interactive chat in a folder, one-shot `perch run`, MCP connections, BYOK/BYOLM modes. Ships on npm as `perchai-cli@2.4.112` (bin `perch`, Node 18+; registry-verified 2026-10-20). ⚠️ Single-vendor lineage: perchai.app and the npm package are the same operator; the only independent confirmation is the registry entry.

## One-command install

Raw command (works if the native dep behaves): `npm install -g perchai-cli`. The TL;DR script exists for the one risky dependency: it pins the verified version, tries the plain install, then falls back to `--omit=optional` and `--ignore-scripts` if `@napi-rs/canvas` breaks it.

## Step-by-step

```bash
pkg install -y nodejs          # Node 18+ required; Termux ships well past that
npm install -g perchai-cli     # or use install.sh for the fallback chain
perch login                    # opens a browser tab on-device, saves session
perch                          # interactive session in the cwd
```

## Termux quirks & workarounds

- npm package name = **`perchai-cli`, bin = `perch`** (not `perchai`). Canvas dep resolved with `canvas-android-arm64` prebuild on-device — no NAPI risk after all (verified 2026-10-20: plain `npm install -g perchai-cli` landed clean; no `--force` needed).
- Pure-JS paths have no phantom-killer/loader issues.
- `perch login` is phone-friendly: browser opens on the same device, token saves locally.

## Sources

- https://www.perchai.app/cli (install + login, Node 18+)
- https://www.perchai.app/docs/using-perch/cli (subcommands, MCP, byok/byolm)
- npm registry `perchai-cli` (verified 2026-10-20, incl. `canvas-android-arm64` resolution)
- Device verification 2026-10-20 (this author's aarch64 Android phone): `perch --version` / `--help`
