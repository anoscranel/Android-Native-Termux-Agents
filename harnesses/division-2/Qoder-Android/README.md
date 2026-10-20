# Qoder on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE (npm hard-block bypassed) · **Confidence:** high — device-verified 2026-10-20 (`qodercli --version` → `1.1.74`)

## TL;DR
```bash
pkg install nodejs && npm install -g @qoder-ai/qodercli --force
```

## What it is
Alibaba's agentic coding CLI (**Qoder CLI**, bins `qodercli`/`qoder`). TUI coding agent; auth via `/login` (Qoder account, Alibaba Cloud Model Studio, Coding/Token plans). Official npm package `@qoder-ai/qodercli` (latest seen `1.1.74`, needs Node ≥ 20).

## One-command install
```bash
pkg install nodejs && npm install -g @qoder-ai/qodercli --force
```
(`--force` is required — the package's platform gate hard-blocks Android with `EBADPLATFORM`; see quirks.)
Scripted equivalent (native-dep handling included):
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-2/Qoder-Android/install.sh | bash
```

## Step-by-step
1. `pkg update && pkg install nodejs` (Termux Node v24.18 satisfies ≥ 20).
2. `npm install -g @qoder-ai/qodercli@1.1.74` (beta channel: `@qoder-ai/qodercli@beta`, the "Node native compatible" preview).
3. Verify `qodercli --version`; launch `qodercli`, type `/login`, choose OAuth — a browser opens. On the phone, copy the printed URL / paste the callback code if the redirect fails.
4. `cd <project> && qodercli`.

Vendor route (desktop): `curl -fsSL https://qoder.com/install | bash` drops a Bun-compiled glibc linux-arm64 binary that cannot exec on bionic directly — needs the native-side glibc runner (`glibc-repo` + `grun`). Prefer npm.

## Termux quirks & workarounds
- **npm EBADPLATFORM hard-block:** the package's `engines`/`os` gate rejects `android` — plain `npm install -g` fails with `EBADPLATFORM`. Override: `npm install -g @qoder-ai/qodercli --force`. Verified boot post-force.
- **Native-dep trio:** `sharp` (ships official android-arm64 prebuilds → resolves), `@silvia-odwyer/photon-node`, `@crosscopy/clipboard` — their install scripts skip under force-mode failures; the CLI boots anyway (image features degrade).
- npm bin layout: `qoder` → `bundle/qoder-npm-dispatcher.cjs`, `qodercli` → `bundle/qodercli.js`. Both land in `$PREFIX/bin`.
- Long sessions: run under `tmux` + `termux-wake-lock` (Android phantom killer).
- Keep installs local — Termux npm prefix is `$PREFIX`, never sudo.
- CN fork `@qodercn-ai/qoderclicn` (qodercn.com) is a separate install base — do not mix.

## Limits
- Device-verified to `--version`; the long TUI/agent loop still depends on Alibaba's backend. `install.sh` pins `1.1.74` (override via `QODER_VERSION=`) and applies `--force` automatically.

## Sources
- https://docs.qoder.com/cli/installation
- https://qoder.com/install
- https://help.aliyun.com/en/model-studio/qoder-agent
- https://registry.npmjs.org/@qoder-ai/qodercli
- https://alibabacloud.com/help/en/lingma/qodercli-cn/user-guide/qoder-cli-cn-get-started-quickly
