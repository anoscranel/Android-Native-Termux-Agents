# Android-Native-Termux-Agents

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE) · **Platform:** Android aarch64 · [Termux](https://github.com/termux/termux-app) (F-Droid / GitHub build) · **Zero proot/chroot/VM**

Run AI coding-harness CLIs **natively on Android via Termux** — no proot, no chroot, no VM, no userland distro emulation. One-command install per harness, step-by-step below each, TL;DR up top in every README.

> **If you have a decent Android mobile, stop letting its idle compute go to waste — put it to work with a full AI agent harness.** These 18 harnesses turn it into a real coding workstation in your pocket.

Everything ships for **aarch64 phones** (arm64). Verified on a real aarch64 Android phone (Termux from F-Droid, Node v24). Devices with ≥4 GB RAM recommended; 6 GB+ comfortable.

## Getting Termux

These instructions were verified on the **F-Droid / GitHub builds** of Termux:

- **F-Droid:** https://f-droid.org/packages/com.termux/
- **Official GitHub (releases APK):** https://github.com/termux/termux-app

The Google Play build is a separate, maintained variant with a different signing key (https://github.com/termux-play-store). It is untested here. Do not mix plugins (Termux:API, Termux:X11 and others) between builds — they must come from the same source as Termux itself.

## TL;DR — the whole zoo, one table

| # | Harness | Verdict | Confidence | One command |
|---|---------|---------|------------|-------------|
| 1 | **Claude Code** | PATCHED-NATIVE · device-proven | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Claude-Code-Android/install.sh \| bash` |
| 2 | **Codex CLI** | PATCHED-NATIVE · device-proven | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Codex-Cli-Android/install.sh \| bash` |
| 3 | **Antigravity (agy)** | PATCHED-NATIVE · device-proven | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Antigravity-Android/install.sh \| bash` |
| 4 | **Grok Build** | NATIVE · device-verified | high | `curl -fsSL https://x.ai/cli/install.sh \| bash` |
| 5 | **Muse Code** | NATIVE · device-verified | high | `curl -fsSL https://dev.meta.ai/install.sh \| bash` |
| 6 | **Cursor (agent)** | PATCHED-NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Cursor-Android/install.sh \| bash` |
| 7 | **Qoder** | PATCHED-NATIVE · device-verified | high | `pkg install nodejs && npm install -g @qoder-ai/qodercli@1.1.74 --force` |
| 8 | **Zcode** ⚠️ unofficial | NATIVE · device-verified | high | `pkg install nodejs && npm install -g zcode-app-cli@latest && zcode` |
| 9 | **Kimi Code** | PATCHED-NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-2/Kimi-Code-Android/install.sh \| bash` |
| 10 | **Minimax Code** | PATCHED-NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-2/Minimax-Code-Android/install.sh \| bash` |
| 11 | **Devin** | PATCHED-NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-3/Devin-Android/install.sh \| bash` |
| 12 | **Droid** | PATCHED-NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-3/Droid-Android/install.sh \| bash` |
| 13 | **Hermes** | NATIVE · device-verified | high | `git clone https://github.com/NousResearch/Hermes-Agent.git ~/.hermes/hermes-agent` + venv — see [README](harnesses/division-4/Hermes-Android/README.md) |
| 14 | **Opencode** | NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-4/Opencode-Android/install.sh \| bash` |
| 15 | **Deepseek Harness** (official `dsh` — Web UI, no CLI) | NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-4/Deepseek-Harness-Android/install.sh \| bash` |
| 16 | **Pi** | NATIVE · device-verified | high | `npm install -g @earendil-works/pi-coding-agent` |
| 17 | **Freebuff** | PATCHED-NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-5/Freebuff-Android/install.sh \| bash` |
| 18 | **Perchai** | NATIVE · device-verified | high | `curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-5/Perchai-Android/install.sh \| bash` |

**Pin to a release:** every URL above tracks the `master` branch. To pin, replace `master` with a release tag, e.g. `v1.0.0`, in any URL.

**Verdict taxonomy** — `NATIVE`: installs and runs as-is. `PATCHED-NATIVE`: runs fully native on the phone after a binary-level fixup (musl re-linking, glibc-runner, or npm shim). `NOT-VIABLE`: no native route exists today (pretend-solutions like proot are deliberately excluded).

## Why "native" is the whole point

The common workaround for glibc-linked CLIs on Android is `proot-distro` — a fake rootfs. proot intercepts every syscall via ptrace, which adds overhead. This repo instead uses four techniques that keep binaries running directly under the Android kernel:

1. **musl re-linking** — swap the ELF interpreter to a musl loader extracted from Alpine APKs (`patchelf --set-interpreter`), so static/musl builds run under bionic. *(Claude Code, Opencode fallback; Codex ships a static musl binary that needs no relink)*
2. **glibc runner** — Termux's `glibc-repo` package ships a real glibc and its loader; the `grun` wrapper (glibc-runner pkg) invokes `<ld.so> --library-path <glibc/lib> <binary>` with the right preload-sanitizing for glibc-linked tools. This is **not** an emulator — the kernel sees ordinary processes, same as invoking a loader by hand on any Linux. *(Cursor, Devin, Droid, Freebuff via `grun`; Antigravity calls the same loader directly: `<ld.so> --library-path <glibc/lib> <binary>`)*
3. **syscall blob patching** — Android's seccomp filter kills `faccessat2` (SIGSYS); a 4-byte AArch64 instruction rewrite downgrades it to plain `faccessat`. *(Antigravity)*
4. **npm shims** — binary-dependency swaps for packages whose JS is fine but whose native modules target glibc builds (`sharp`→WASM, `ripgrep` swap, `node-pty` source build). *(Qoder, Kimi, Minimax, Deepseek Harness)*. Perchai needs no shim today; its installer only keeps fallbacks.

Optional loopback proxy: the Codex and Antigravity wrappers route traffic through `127.0.0.1:18080` **only if** a proxy supervisor (`~/bin/ensure-local-proxy.sh`) is installed. Without it they leave proxy settings alone. Never export such a proxy shell-wide: if it dies, every `curl` in that shell fails.

## Layout

```
harnesses/
  division-1/   Claude-Code · Codex-Cli · Antigravity · Grok-Build · Muse-Code · Cursor
  division-2/   Qoder · Zcode · Kimi-Code · Minimax-Code
  division-3/   Devin · Droid
  division-4/   Hermes · Opencode · Deepseek-Harness · Pi
  division-5/   Freebuff · Perchai
```

Every `<Name>-Android/` dir has a README with **TL;DR first, one-command install, then step-by-step**, Termux-specific quirks (phantom process killer, `TMPDIR`, seccomp, phone-browser auth flows), honest limits, and sources. Dirs with multi-step installs also carry an idempotent `install.sh`. Versions are pinned where the vendor allows; Opencode, Devin and Cursor follow the vendor's latest — see each README. Downloads are sha256-verified where a hash exists.

## Termux survival notes (apply everywhere)

- **Phantom process killer**: Android caps child processes at ~32 device-wide, counted across all apps' child processes (whatever libc they use). Run long harness sessions inside `tmux`, and disable child-process restrictions in Developer Options.
- **TMPDIR**: several tools assume a real `/tmp`; Termux's `$PREFIX/tmp` works but some installers need it exported explicitly.
- Use the **F-Droid or GitHub build of Termux** (see above). The Google Play build is maintained but untested here.
- Auth flows that expect a desktop browser still work — they print a URL you open manually on the phone.

## Confidence & verification

Each harness was installed and run on a real aarch64 Android phone on 2026-10-20: it printed its version or help output under Termux. Four also completed a full agent turn against an OpenAI-compatible endpoint: OpenCode, Kimi Code, Pi and Hermes.

The Claude Code, Codex and Antigravity scripts reproduce the payload method that runs on that phone. The payload versions they pin differ from the phone's own installs, and the scripts themselves were not re-run there. Every script is idempotent, so the same line doubles as the upgrade path. Anything else unverified is flagged ⚠️ in that harness's README.

## Disclaimer

- **Not affiliated** with Anthropic, OpenAI, Google, xAI, Meta, Cursor, Alibaba, Cognition, Factory, Perch AI, DeepSeek, Nous Research, Codebuff, Moonshot AI, SST/Anomaly, Earendil, Z.ai, the ZCode project, MiniMax, the maintainers of the payload packs and forks linked here (`mrfandu1/patched-cli-payloads`, `bd-loser/opencode-bionic`, `kingsword09/zcode-cli`), or any other vendor named here. All trademarks belong to their owners.
- **Community-maintained unofficial guides.** Where a CLI has an official upstream, the README links it and prefers it; fork/patch packs are labeled (e.g. ⚠️ unofficial on Zcode). This repo does not fork any agent.
- **Trust boundaries are honest, not implicit.** Some harnesses download and run pinned third-party payload packs on-device (e.g. `mrfandu1/patched-cli-payloads` for Claude Code / Codex / Antigravity, `bd-loser/opencode-bionic` builds for Opencode). Each README says what it fetches and from where. The payload hashes are pinned in the scripts from the release's own `SHA256SUMS` file as published on 2026-10-21 (trust-on-first-use): they detect a changed file, but they do not prove who built it. That is a *documented* risk decision you make by running them — review `install.sh` first (`curl ... -o install.sh && less install.sh && bash install.sh`) the way you would on any machine.
- **`curl | bash` is the delivery convenience, not the security model.** Almost every TL;DR here is a shell pipe. The security comes from what the scripts *do* (pinned versions where possible, sha256 checks where a hash exists, no config-touching, no shell-wide env changes) — read one before trusting the pattern blindly on anything else.
- **Unlicensed rebuilds.** Some payload packs are unlicensed third-party rebuilds of proprietary software; running them may breach the vendor's terms. That is your decision.
- **No warranty; readers' devices, readers' choices.** Verified on one handset at one point in time; vendors ship nightly. Checksums and pin overrides (`<H>_VERSION=`) exist for exactly that reason. Credentials, API keys and OAuth tokens you put into these agents are your own responsibility, same as anywhere.
- **MIT licensed.** See `LICENSE`.

## Contributing

More harnesses welcome — same bar: real CLI, native route (or an honest NOT-VIABLE writeup), one-command first, pinned versions, no proot. Open a PR with the same README skeleton.

## License

MIT — see `LICENSE`.
