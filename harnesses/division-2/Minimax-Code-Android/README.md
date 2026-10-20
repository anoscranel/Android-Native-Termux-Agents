# MiniMax Code on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — device-verified 2026-10-20 (`mcode 0.6.12`)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-2/Minimax-Code-Android/install.sh | bash
```

## What it is
MiniMax's official open-source TUI coding agent **MiniMax Code** (bins `mcode`, `mcode-tools`; repo `MiniMax-AI/minimax-code`). Interactive TUI plus `mcode exec` for shell/CI automation. Auth via MiniMax Token Plan subscription key (`sk-...`) from `platform.minimax.io`. npm `@minimax-ai/code` (latest `0.6.12`, engines Node `>=22.19 <23 || >=24 <27`).

⚠️ Distinct from MiniMax's **other** official CLI `mmx` (`mmx-cli`, multimodal media platform) — do not confuse the two.

## One-command install
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-2/Minimax-Code-Android/install.sh | bash
```
The script = npm install **plus** the mandatory ripgrep swap below — that is why one npm line alone is not enough.

## Step-by-step
1. `pkg install nodejs ripgrep build-essential python` (Termux Node v24.18 sits inside `<27`).
2. `npm install -g @minimax-ai/code@0.6.12 --force` (the `--force` is mandatory — the package's platform gate hard-blocks Android; see quirks)
3. **Ripgrep shim (Termux fix):** `@vscode/ripgrep` downloads a glibc linux-arm64 `rg` that won't exec on bionic. Replace it with Termux's own:
   ```bash
   cp "$PREFIX/bin/rg" "$PREFIX/lib/node_modules/@minimax-ai/code/node_modules/@vscode/ripgrep/bin/rg"
   ```
   If the npm install already died at the `@vscode/ripgrep` postinstall: `mkdir -p` that `bin` dir, copy first, then re-run the npm install.
4. Log in with a subscription key from `platform.minimax.io/console/plan` (phone-friendly paste flow).

Vendor route (desktop): `curl -fsSL https://filecdn.minimax.chat/public/install.sh | bash` — explicitly does **not** support musl; Termux users stay on the npm path.

## Termux quirks & workarounds
- **Bins are `mcode` + `mcode-tools`** — NOT `minimax`. The npm engine gate also hard-blocks Android; use `npm install -g @minimax-ai/code@0.6.12 --force`.
- `better-sqlite3` scripts are skipped under `--force` (optional dep — CLI boots without it). `@vscode/ripgrep` ships glibc linux-arm64; the shim in step 3 handles it (Termux `rg` drop-in).
- On-device Node 24.18 needs no engine override.
- Long agent sessions: `tmux` + `termux-wake-lock` (Android phantom process killer).
- `mcode exec` = headless/CI mode, scriptable.

## Limits
- Device-verified to `--help`+boot with the npm `--force` + ripgrep shim; the TUI itself needs a key to reach fully.

## Sources
- https://agent.minimax.io/docs/cli/quick-start
- https://github.com/MiniMax-AI/minimax-code
- https://registry.npmjs.org/@minimax-ai/code
- https://github.com/MiniMax-AI/cli
- https://platform.minimax.io/docs/m-plan/minimax-cli
