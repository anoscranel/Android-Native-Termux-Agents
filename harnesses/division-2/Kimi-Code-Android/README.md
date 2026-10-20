# Kimi Code on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — device-verified 2026-10-20 (`kimi 2.2.0`; node-pty source build skipped by stock install, then a full agent turn against an OpenAI-compatible endpoint)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-2/Kimi-Code-Android/install.sh | bash
```

## What it is
Moonshot AI's official terminal coding agent **Kimi Code CLI** (bin `kimi`), driven by Kimi models (K2.5). MIT, repo `MoonshotAI/kimi-code`; npm `@moonshot-ai/kimi-code` (latest `2.2.0`, engine Node ≥ 22.19). Speaks ACP for editor integration (`kimi acp`).

⚠️ The old pure-Python PyPI `kimi-cli` is **archived** — do not use. ⚠️ `kimi-api.com/kimi-cli` is an SEO imposter (third-party proxy, not Moonshot).

## One-command install
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-2/Kimi-Code-Android/install.sh | bash
```
The npm one-liner `npm install -g @moonshot-ai/kimi-code` works once build tools are in place; the script installs them for you.

## Step-by-step
1. `pkg install nodejs make clang python` — the npm package depends on native `node-pty`, and node-gyp compiles it from source (no android-arm64 prebuild). Termux Node v24.18 satisfies ≥ 22.19.
2. `npm install -g @moonshot-ai/kimi-code@2.2.0`
3. `kimi --version`, then `cd <project> && kimi`.
4. First launch `/login` → **Kimi Code OAuth** (browser device-flow; on the phone the URL opens in the browser, approve, code returns automatically or paste the printed code) **or** a **Moonshot AI Open Platform API key**.

Vendor route (desktop): `curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash` downloads a linux-arm64 glibc binary and explicitly rejects musl; on bionic it needs the native-side glibc runner (`glibc-repo` + `grun`). Prefer npm.

## Termux quirks & workarounds
- node-pty is the known friction point. If node-gyp fails: `pkg install build-essential lld`, retry; also try `npm config set scripts-prepend-node-path true`. **Verified on a real Android phone:** node-gyp build inside `.pnpm`/global node_modules completed clean, CLI booted (`--help`).
- Deps are modest (`ws`, `qrcode`, `@mariozechner/clipboard`, `node-pty`) — no dlopen-heavy natives.
- Phone OAuth: `termux-open-url` assist, keep the phone unlocked, callback loops to localhost.
- **BYOK works:** add a custom provider in `~/.kimi-code/config.toml` (`type = "openai"`, `baseUrl`, literal `apiKey`) plus a `[models.<alias>]` entry (must include `maxContextSize`) — verified end-to-end on-device. Note: `apiKey` is read as a literal string; the `apiKeyEnv` indirection wasn't honored in 2.2.0.
- Long sessions: `tmux` + `termux-wake-lock` (Android phantom process killer).
- `kimi acp` (Zed/JetBrains integration) is desktop-oriented — skip on phone.

## Limits
- Device-verified to `--help`; the full agentic loop still depends on Moonshot's backend. No published npm checksums; pinned by version only (`install.sh` pins `2.2.0`, override via `KIMI_VERSION=`).

## Sources
- https://github.com/MoonshotAI/kimi-code
- https://moonshotai.github.io/kimi-code/en/guides/getting-started
- https://pypi.org/pypi/kimi-cli/json
- https://registry.npmjs.org/@moonshot-ai/kimi-code
