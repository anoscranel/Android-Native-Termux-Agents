# DeepSeek Harness on Termux (native Android, no proot)
**Verdict:** NATIVE · **Confidence:** high — device-verified 2026-10-20 (dsh 0.1.0-rc.6, Web UI served HTTP 200, all plugins loaded)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-4/Deepseek-Harness-Android/install.sh | bash && dsh web --host 127.0.0.1 --port 3080
```
Then open `http://127.0.0.1:3080` in the phone's browser.

## What it is
DeepSeek Harness (`dsh`) is DeepSeek AI's official open-source agent harness (MIT, repo `deepseek-ai/deepseek-harness`). It has **no terminal CLI**: the default is a Web UI served from your phone. "Everything is a plugin": profiles boot plugin stacks, and the `web` profile serves the browser UI. You can edit files, run commands and delegate to subagents from the browser. Developer preview: expect breaking changes.

## One-command install
The TL;DR script does every step below. It is idempotent, pins `@deepseek-ai/dsh@0.1.0-rc.6` (override with `DSH_VERSION=`) and pins `node-gyp@13.0.1` (override with `NODE_GYP_VERSION=`).

## Step-by-step
1. `pkg install -y nodejs pnpm python make clang cmake curl && npm i -g node-gyp@13.0.1`
2. `mkdir -p ~/.local/dsh && cd ~/.local/dsh && pnpm add @deepseek-ai/dsh@0.1.0-rc.6 @img/sharp-wasm32@0.35.3` (the wasm package replaces native sharp)
3. node-pty, source build: `(cd node_modules/.pnpm/node-pty@*/node_modules/node-pty && node-gyp rebuild)`
4. koffi, patch + build: in `node_modules/.pnpm/koffi@*/node_modules/koffi/lib/native/base/base.cc`, inside `static StatResult StatAt`, change the guard to `#if defined(__linux__) && !defined(__ANDROID__)`. Bionic's `statx` is a macro that clashes; the `#else` branch uses plain `fstatat`. Then `(cd .../koffi && node ./cnoke.cjs -P . -D src/koffi --prebuild --release)`.
5. Wrapper `~/.local/bin/dsh`: `exec node --expose-internals "$HOME/.local/dsh/node_modules/@deepseek-ai/dsh/lib/bin.js" "$@"`
6. `dsh web --host 127.0.0.1 --port 3080` — open that URL in the phone browser.

If a version bump leaves two copies in the pnpm store, the script builds the newest one.

## Termux quirks & workarounds
- `--no-open` doesn't exist at rc.6 (the docs are ahead) — open the printed URL by hand.
- npm/pnpm silently skip the native deps' install scripts (no android-arm64 prebuilds). Without steps 3–4 the `web` profile crashes at plugin load.
- The UI defaults to zh-CN; switch it in Settings.
- `dsh plugin ...` forwards to pnpm inside `~/.local/dsh`.
- Phantom process killer (~32 child processes, device-wide): use `tmux` and disable child-process restrictions in Developer Options.

## Limits
- Developer-preview pin. The koffi patch finds its target by name and fails loudly if the file changes.
- The full `login → task` flow was not exercised; verified = clean boot, UI HTTP 200, plugins loaded.

## Sources
- https://github.com/deepseek-ai/deepseek-harness (official, MIT)
- https://www.deepseek.com/en/harness/
- npm `@deepseek-ai/dsh@0.1.0-rc.6` (checked 2026-10-20)
- Device verification 2026-10-20 (aarch64 Android phone): boot, UI serve, both native fixes
