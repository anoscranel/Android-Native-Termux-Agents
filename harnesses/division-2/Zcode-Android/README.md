# Zcode on Termux (native Android, no proot)
**Verdict:** NATIVE · **Confidence:** high — device-verified 2026-10-20 (pure npm global, runs on Termux Node)

## TL;DR
```bash
pkg install nodejs && npm install -g zcode-app-cli@latest && zcode
```

## What it is
⚠️ **Unofficial.** `zcode-app-cli` (by `kingsword09`) is a community terminal client, **not affiliated with or endorsed by Z.ai**. It packages a pinned ZCode Desktop runtime with compatibility patches. Its own code is MIT per its README; bundled runtime content keeps upstream licenses.

The runtime is the **ZCode agent** (upstream `zai-org/ZCode`, Apache-2.0, Z.ai / GLM family). Pure Node (needs ≥ 22.19); deps `playwright-core` + `@earendil-works/pi-tui`. No native toolchain, no binary downloads.

## One-command install
The TL;DR line is genuinely one command — no install script needed. Requires Node ≥ 22.19 (Termux's current Node v24.18 satisfies it).

## Step-by-step
1. `pkg install nodejs` (skip if Node ≥ 22.19 already present).
2. `npm install -g zcode-app-cli@latest` (latest published: `3.16.2-38`).
3. Run `zcode`. First launch creates `~/.zcode/cli/setting.json` and opens a setup wizard for the 3 model-access paths (see `docs/CONFIGURATION.md` upstream); provider config goes to `~/.zcode/v2/provider_config.json`, shared with the ZCode desktop app. Reopen with `/setup`; Esc skips.
4. Verify wiring: `npm ls -g --depth=0 | grep zcode`.

Upgrade: re-run `npm install -g zcode-app-cli@latest`.

## Termux quirks & workarounds
- Re-running the npm line upgrades in place; config under `~/.zcode/` is untouched.
- Auth runs entirely through the TUI wizard — no browser OAuth dance for the credential-free default. Handy on a phone.
- Phantom process killer (~32 child processes, device-wide): use `tmux` and disable child-process restrictions in Developer Options.
- No seccomp/TMPDIR gotchas observed; the launcher spawns the runtime as a child process.

## Limits
- Unofficial → the bundled runtime is a **pinned** snapshot of the ZCode desktop app; feature drift vs upstream is expected — check repo releases when debugging.
- Third-party trust decision: you are trusting `kingsword09`'s packaging of the runtime. Unpinned: `@latest` follows the newest release.

## Sources
- https://github.com/kingsword09/zcode-cli
- https://www.npmjs.com/package/zcode-app-cli
- https://github.com/zai-org/ZCode
