# Kimi Code on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — device-verified 2026-10-20 (`kimi 2.2.0`; node-pty built from source; a full agent turn against a BYOK OpenAI-compatible endpoint)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-2/Kimi-Code-Android/install.sh | bash
```

## What it is
Moonshot AI's official terminal coding agent **Kimi Code CLI** (bin `kimi`), driven by Kimi models (K2.5). MIT, repo `MoonshotAI/kimi-code`; npm `@moonshot-ai/kimi-code` (latest `2.2.0`, engine Node ≥ 22.19). Speaks ACP for editor integration (`kimi acp`).

⚠️ The old pure-Python PyPI `kimi-cli` is **archived** — do not use. ⚠️ `kimi-api.com/kimi-cli` is an SEO imposter (third-party proxy, not Moonshot).

## One-command install
The TL;DR line is the one command. The npm one-liner `npm install -g @moonshot-ai/kimi-code` works once build tools are in place; the script installs them for you.

## Step-by-step
1. `pkg install nodejs make clang python` — the npm package depends on native `node-pty`, and node-gyp compiles it from source (no android-arm64 prebuild). Termux Node v24.18 satisfies ≥ 22.19.
2. `npm install -g @moonshot-ai/kimi-code@2.2.0`
3. `kimi --version`, then `cd <project> && kimi`.
4. First launch `/login` → **Kimi Code OAuth** (device flow, see quirks) **or** a **Moonshot AI Open Platform API key**.

Vendor script (`curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash`) downloads a linux-arm64 glibc binary and rejects musl; on Bionic it needs the glibc runner (`glibc-repo` + `grun`). Prefer npm.

## Termux quirks & workarounds
- node-pty is the known friction point. If node-gyp fails: `pkg install build-essential lld` and retry (the script does this once). On the test phone the build completed clean.
- Deps are modest (`ws`, `qrcode`, `@mariozechner/clipboard`, `node-pty`) — no heavy native libraries.
- Phone OAuth is a device flow: open the URL with `termux-open-url`, approve, and paste the code if it does not return on its own. No localhost callback.
- **BYOK works:** add a custom provider in `~/.kimi-code/config.toml` (`type = "openai"`, `baseUrl`, literal `apiKey`) plus a `[models.<alias>]` entry (must include `maxContextSize`) — verified end-to-end on-device. Note: `apiKey` is read as a literal string; the `apiKeyEnv` indirection wasn't honored in 2.2.0.
- Phantom process killer (~32 child processes, device-wide): use `tmux` and disable child-process restrictions in Developer Options.
- Skip `kimi acp` (Zed/JetBrains editor integration) on a phone.

## Limits
- Device-verified to `--help` plus one full agent turn via a BYOK OpenAI-compatible endpoint. Kimi OAuth and Moonshot's own backend were not tested. No published npm checksums; pinned by version only (`KIMI_VERSION=` overrides).

## Sources
- https://github.com/MoonshotAI/kimi-code
- https://moonshotai.github.io/kimi-code/en/guides/getting-started
- https://pypi.org/pypi/kimi-cli/json
- https://registry.npmjs.org/@moonshot-ai/kimi-code
