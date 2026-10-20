# DeepSeek Harness on Termux (native Android, no proot)

**Verdict:** NATIVE · **Confidence:** high — device-verified 2026-10-20 (dsh 0.1.0-rc.6, Web UI served HTTP 200, all plugins loaded)

## TL;DR

DeepSeek Harness (`dsh`) is DeepSeek AI's official open-source agent harness (MIT). It has **no terminal CLI — the default is a Web UI** served from your phone: `dsh web` → open `http://127.0.0.1:3080`. Fully native on Termux; two native npm deps need a source build. One command below; verified on a real phone.

## What it is

Official repo: deepseek-ai/deepseek-harness. "Everything-is-a-plugin" agent harness on Cordis. Profiles boot plugin stacks; the `web` profile serves the browser UI. Edit files, run commands, delegate subagents — from the phone's browser. Developer preview: expect breaking changes.

## One-command install

```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-4/Deepseek-Harness-Android/install.sh | bash
```

## Step-by-step

1. `pkg install -y nodejs pnpm python make clang cmake curl && npm i -g node-gyp`
2. `mkdir -p ~/.local/dsh && cd ~/.local/dsh && pnpm add @deepseek-ai/dsh @img/sharp-wasm32@0.35.3` (wasm shim replaces native sharp)
3. node-pty, source build: `(cd node_modules/.pnpm/node-pty@*/node_modules/node-pty && node-gyp rebuild)`
4. koffi, patch + build: in `node_modules/.pnpm/koffi@*/node_modules/koffi/lib/native/base/base.cc`, inside function `static StatResult StatAt`, change its guard to `#if defined(__linux__) && !defined(__ANDROID__)` (bionic's `statx` is a macro that collides; the fallback `#else` branch uses plain fstatat) — then `(cd .../koffi && node ./cnoke.cjs -P . -D src/koffi --prebuild --release)`
5. Wrapper `~/.local/bin/dsh`: `exec node --expose-internals "$HOME/.local/dsh/node_modules/@deepseek-ai/dsh/lib/bin.js" "$@"`
6. `dsh web --host 127.0.0.1 --port 3080` — open that URL in the phone browser.

`install.sh` automates all steps idempotently and pins `@deepseek-ai/dsh@0.1.0-rc.6` (override via `DSH_VERSION=`).

## Termux quirks & workarounds

- `--no-open` doesn't exist at rc.6 (docs drift) — harmless; open the printed URL manually.
- npm/pnpm silently skip the native deps' install scripts (no android-arm64 prebuilds); without steps 3–4 the `web` profile crashes at plugin load.
- UI defaults to zh-CN; switchable in Settings.
- `dsh plugin ...` forwards to pnpm inside `~/.local/dsh`.

## Limits

- Developer-preview pin; the koffi patch is anchored by name and fails loudly if the file changes.
- Full `login → task` flow not yet exercised; verified = clean boot + UI HTTP 200 + plugin trees loaded.

## Sources

- https://github.com/deepseek-ai/deepseek-harness (official, MIT)
- https://www.deepseek.com/en/harness/
- npm `@deepseek-ai/dsh@0.1.0-rc.6` (verified 2026-10-20)
- Device verification 2026-10-20 (this author's aarch64 Android phone): boot, UI serve, both native fixes

