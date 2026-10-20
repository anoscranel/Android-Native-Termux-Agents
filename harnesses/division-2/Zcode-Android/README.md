# Zcode on Termux (native Android, no proot)

> ⚠️ **Unofficial CLI** — `zcode-app-cli` (by `kingsword09`) is a **community/unofficial** terminal client. It is **not affiliated with or endorsed by Z.ai** (the official vendor). It packages a pinned ZCode Desktop runtime with compatibility patches. Its own code is MIT; bundled runtime content keeps upstream licenses.

**Verdict:** NATIVE · **Confidence:** high

## TL;DR
```bash
pkg install nodejs && npm install -g zcode-app-cli@latest && zcode
```

## What it is
Community terminal client for the **ZCode agent runtime** (upstream `zai-org/ZCode`, Apache-2.0, Z.ai / GLM family). Pure Node (needs ≥ 22.19); deps `playwright-core` + `@earendil-works/pi-tui`. No native toolchain, no binary downloads — cleanest install of division 2. On-device autopsy (2026-10-20) confirms a pure npm global.

## One-command install
```bash
pkg install nodejs && npm install -g zcode-app-cli@latest && zcode
```
Genuinely one command — no install script needed. Requires Node ≥ 22.19 (Termux's current Node v24.18 satisfies it).

## Step-by-step
1. `pkg install nodejs` (skip if Node ≥ 22.19 already present).
2. `npm install -g zcode-app-cli@latest` (latest published: `3.16.2-38`).
3. Run `zcode`. First launch creates `~/.zcode/cli/setting.json` and opens an in-TUI setup wizard covering the 3 model-access paths (see `docs/CONFIGURATION.md` upstream); provider config writes to `~/.zcode/v2/provider_config.json`, shared with ZCode Desktop. Reopen with `/setup`; Esc skips.
4. Verify wiring: `npm ls -g --depth=0 | grep zcode`.

Upgrade: re-run `npm install -g zcode-app-cli@latest`.

## Termux quirks & workarounds
- Re-running the npm line upgrades in place; config under `~/.zcode/` is untouched.
- Auth runs entirely through the TUI wizard — no browser OAuth dance for the credential-free default. Handy on a phone.
- Long sessions under `tmux` + `termux-wake-lock` (Android's background-process killer is aggressive on some OEMs).
- No seccomp/TMPDIR gotchas observed; the launcher spawns the runtime as a child process.

## Limits
- Unofficial → bundled runtime is a **pinned** ZCode Desktop snapshot; feature drift vs upstream is expected — check repo releases when debugging.
- Third-party trust decision: you are trusting `kingsword09`'s packaging of the runtime.

## Sources
- https://github.com/kingsword09/zcode-cli
- https://www.npmjs.com/package/zcode-app-cli
- https://github.com/zai-org/ZCode
