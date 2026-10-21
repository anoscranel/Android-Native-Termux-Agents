# Android-Native-Termux-Agents

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE) · **Platform:** Android aarch64 · [Termux](https://github.com/termux/termux-app) (F-Droid build) · **Zero proot/chroot/VM**

Run AI coding-harness CLIs **natively on Android via Termux** — no proot, no chroot, no VM, no userland distro emulation. One-command install per harness, step-by-step below each, TL;DR up top in every README.

> **If you have a decent Android mobile, stop letting its idle compute go to waste — put it to work with a full AI agent harness.** These 18 harnesses turn it into a real coding workstation in your pocket.

Everything ships for **aarch64 phones** (arm64). Verified on a real aarch64 Android phone (Termux from F-Droid, Node v24). Devices with ≥4 GB RAM recommended; 6 GB+ comfortable.

## Getting Termux

Install Termux **from F-Droid or the official GitHub repo** — the Google Play build is deprecated and throws unwritable-path errors:

- **F-Droid:** https://f-droid.org/packages/com.termux/
- **Official GitHub (releases APK):** https://github.com/termux/termux-app

## TL;DR — the whole zoo, one table

| # | Harness | Verdict | Confidence | One command |
|---|---------|---------|------------|-------------|
| 1 | **Claude Code** | PATCHED-NATIVE · device-proven | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Claude-Code-Android/install.sh \| bash` |
| 2 | **Codex CLI** | PATCHED-NATIVE · device-proven | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Codex-Cli-Android/install.sh \| bash` |
| 3 | **Antigravity (agy)** | PATCHED-NATIVE · device-proven | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Antigravity-Android/install.sh \| bash` |
| 4 | **Grok Build** | NATIVE · device-verified | high | `curl -fsSL https://x.ai/cli/install.sh \| bash` |
| 5 | **Muse Code** | NATIVE · device-verified | high | `curl -fsSL https://dev.meta.ai/install.sh \| bash` |
| 6 | **Cursor (agent)** | PATCHED-NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Cursor-Android/install.sh \| bash` |
| 7 | **Qoder** | PATCHED-NATIVE · device-verified | high | `pkg install nodejs && npm install -g @qoder-ai/qodercli --force` |
| 8 | **Zcode** ⚠️ unofficial | NATIVE | high | `pkg install nodejs && npm install -g zcode-app-cli@latest && zcode` |
| 9 | **Kimi Code** | PATCHED-NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-2/Kimi-Code-Android/install.sh \| bash` |
| 10 | **Minimax Code** | PATCHED-NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-2/Minimax-Code-Android/install.sh \| bash` |
| 11 | **Devin** | PATCHED-NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-3/Devin-Android/install.sh \| bash` |
| 12 | **Droid** | PATCHED-NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-3/Droid-Android/install.sh \| bash` |
| 13 | **Hermes** | NATIVE | high | `curl -fsSL https://hermes-agent.nousresearch.com/install.sh \| bash` |
| 14 | **Opencode** | NATIVE | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-4/Opencode-Android/install.sh \| bash` |
| 15 | **Deepseek Harness** (official `dsh` — Web UI, no CLI) | NATIVE | high — device-verified | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-4/Deepseek-Harness-Android/install.sh \| bash` |
| 16 | **Pi** | NATIVE | high | `npm install -g @earendil-works/pi-coding-agent` |
| 17 | **Freebuff** | PATCHED-NATIVE (official tarball + `grun`) | high — device-verified | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-5/Freebuff-Android/install.sh \| bash` |
| 18 | **Perchai** | NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-5/Perchai-Android/install.sh \| bash` |

**Verdict taxonomy** — `NATIVE`: installs and runs as-is. `PATCHED-NATIVE`: runs fully native on the phone after a binary-level fixup (musl re-linking, glibc-runner, or npm shim). `NOT-VIABLE`: no native route exists today (pretend-solutions like proot are deliberately excluded).

## Why "native" is the whole point

The common workaround for glibc-linked CLIs on Android is `proot-distro` — a fake rootfs that runs every syscall through ptrace interception. It costs 30-60% CPU overhead, doubles battery drain, and breaks inotify. This repo instead uses four techniques that keep binaries running directly under the Android kernel:

1. **musl re-linking** — swap the ELF interpreter to a musl loader extracted from Alpine APKs (`patchelf --set-interpreter`), so static/musl builds run under bionic. *(Claude Code, Codex, Opencode fallback)*
2. **glibc runner** — Termux's `glibc-repo` package ships a real glibc and its loader; the `grun` wrapper (glibc-runner pkg) invokes `<ld.so> --library-path <glibc/lib> <binary>` with the right preload-sanitizing for glibc-linked tools. This is **not** an emulator — the kernel sees ordinary processes, same as invoking a loader by hand on any Linux. *(Antigravity, Cursor, Devin, Droid, Freebuff)*
3. **syscall blob patching** — Android's seccomp filter kills `faccessat2` (SIGSYS); a 4-byte AArch64 instruction rewrite downgrades it to plain `faccessat`. *(Antigravity)*
4. **npm shims** — binary-dependency swaps for packages whose JS is fine but whose native modules target glibc builds (`sharp`→WASM, `ripgrep` swap, `node-pty` source build). *(Qoder, Kimi, Minimax, Perchai, Deepseek Harness)*

A loopback proxy (`127.0.0.1:18080` — **inside the wrapper only**, never exported shell-wide — Android's phantom-process killer will take down your whole shell) lets musl-linked CLIs route API traffic cleanly.

## Layout

```
harnesses/
  division-1/   Claude-Code · Codex-Cli · Antigravity · Grok-Build · Muse-Code · Cursor
  division-2/   Qoder · Zcode · Kimi-Code · Minimax-Code
  division-3/   Devin · Droid
  division-4/   Hermes · Opencode · Deepseek-Harness · Pi
  division-5/   Freebuff · Perchai
```

Every `<Name>-Android/` dir has a README with **TL;DR first, one-command install, then step-by-step**, Termux-specific quirks (phantom process killer, `TMPDIR`, seccomp, phone-browser auth flows), honest limits, and sources. Dirs with multi-step installs also carry an idempotent `install.sh` pinned to exact versions with checksum verification where the vendor publishes hashes.

## Termux survival notes (apply everywhere)

- **Phantom process killer** silently caps ~32 child processes per shell session, device-wide — run long harness sessions inside `tmux`, and never export supervisor proxies shell-wide.
- **TMPDIR**: several tools assume a real `/tmp`; Termux's `$PREFIX/tmp` works but some installers need it exported explicitly.
- Use the **F-Droid build of Termux** (see above — Google Play build is deprecated).
- Auth flows that expect a desktop browser still work — they print a URL you open manually on the phone.

## Confidence & verification

Rows marked **device-verified** (device-proven) were *installed and executed* on the author's aarch64 Android phone on 2026-10-20 — version-pinned rows print `--version`/`--help` under Termux itself, patched binaries via the techniques above. The one-command installers were executed end-to-end; each is idempotent, so the same line doubles as the upgrade path. **Full working agent sessions** (not just boot) are verified for OpenCode, Kimi Code, Pi, and Hermes against an OpenAI-compatible endpoint. Anything unverified by design (vendor-OAuth-locked loops, paid-plan gates) is flagged ⚠️ inside that harness's README. Nothing here pretends otherwise.

## Disclaimer

- **Not affiliated** with Anthropic, OpenAI, Google, xAI, Meta, Cursor, Alibaba, Cognition, Factory, Perch AI, DeepSeek, Nous Research, Codebuff, the ZCode project, MiniMax, or any other vendor named here. All trademarks belong to their owners.
- **Community-maintained unofficial guides.** Where a CLI has an official upstream, the README links it and prefers it; fork/patch packs are labeled (e.g. ⚠️ unofficial on Zcode). Where upstream ships a `*-linux-arm64` binary, this repo gets the running shape onto Termux without changing the binary's behavior — it does not fork the agent itself.
- **Trust boundaries are honest, not implicit.** Some harnesses download and run pinned, sha256-verified third-party payload packs on-device (e.g. `mrfandu1/patched-cli-payloads` for Claude Code / Codex / Antigravity, `bd-loser/opencode-bionic` builds for Opencode). Each README says what it fetches and from where. That is a *documented* risk decision you make by running them — review `install.sh` first (`curl ... -o install.sh && less install.sh && bash install.sh`) the way you would on any machine.
- **`curl | bash` is the delivery convenience, not the security model.** Almost every TL;DR here is a shell pipe. The security comes from what the scripts *do* (pinned versions, checksums where vendors publish them, no config-touching, no shell-wide env changes) — read one before trusting the pattern blindly on anything else.
- **No warranty; readers' devices, readers' choices.** Verified on one handset at one point in time; vendors ship nightly. Checksums and pin overrides (`<H>_VERSION=`) exist for exactly that reason. Credentials, API keys and OAuth tokens you put into these agents are your own responsibility, same as anywhere.
- **MIT licensed.** See `LICENSE`.

## Contributing

More harnesses welcome — same bar: real CLI, native route (or an honest NOT-VIABLE writeup), one-command first, pinned versions, no proot. Open a PR with the same README skeleton.

## License

MIT — see `LICENSE`.
