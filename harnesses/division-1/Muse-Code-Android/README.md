# Muse Code on Termux (native Android, no proot)
**Verdict:** NATIVE · **Confidence:** high — device-verified 2026-10-20 (`muse 1.4.11-R6667.1` ran natively)

## TL;DR
```bash
curl -fsSL https://dev.meta.ai/install.sh | bash
```
(⚠️ `bash`, not `sh`.)

## What it is
Muse Code — Meta's official terminal agent for Muse Spark: plans, edits files, runs commands with approvals; claims an OS sandbox from first run. macOS + Linux (x86_64 & aarch64). The `aarch64_linux` artifact (v1.4.11-R6667.1) is a **statically linked aarch64 ELF** (byte-verified: no `INTERP` segment), so it should run on Bionic unmodified.

## One-command install
The TL;DR line is the official installer. Then `muse --version`; sign-in on first run (browser) or `META_API_KEY` for headless/CI.

## Step-by-step
1. Requirements: only `curl` + `mktemp` (Termux base). No Node/Python.
2. The installer drops a **launcher** into `${MUSE_INSTALL_DIR:-$HOME/.local/bin}/muse`, added to PATH via shell rc (`MUSE_NO_MODIFY_PATH=1` suppresses; `MUSE_LOGIN=0` suppresses login).
3. The launcher detects `Linux:aarch64` → `aarch64_linux`, queries `https://api.meta.ai/muse-code/channels/muse-stable`, downloads + **sha256-verifies** the artifact from `lookaside.facebook.com`; self-updates hourly (`MUSE_UPDATE_INTERVAL_SECONDS`).
4. Verified (2026-10-20): channel → `1.4.11-R6667.1`; per-arch sha256 in lookaside `manifest.json`; ELF `statically linked`.
5. Size warning: binary is **~330 MB** — plan disk/data.

## Auth on a phone
Launcher drives an **OAuth 2.0 device-code grant** against `auth.meta.com` (verified in live launcher source): prints URL + code, approve in browser (`termux-open-url`), CLI polls. Credentials at `${XDG_CONFIG_HOME:-$HOME/.config}/muse/auth.json` (`MUSE_AUTH_PATH` overrides). No localhost callback server — most phone-friendly auth here. ⚠️ `termux-open-url` needs `pkg install termux-api` + the Termux:API app.

## Termux quirks & workarounds
- **`sh` piping silently breaks the installer** (bash-only `[[...]]` tests) — pipe to `bash`, not `sh`.
- Install dir **must live under `$HOME`** — the installer refuses `$TMPDIR` paths (we hit and confirmed this). Use `~/.muse-test` or default `~/.local`; `MUSE_INSTALL_DIR=$HOME/<dir> MUSE_NO_MODIFY_PATH=1 MUSE_LOGIN=0` keeps it sandboxed.
- `git` required at runtime for worktree features — `pkg install git`.
- Phantom process killer / TMPDIR / tmux — see [Claude-Code-Android](../Claude-Code-Android/README.md).

## Limits
- Device-verified to `--version` only (1.4.11-R6667.1, 345,970,792-byte binary matches manifest). No full agent loop on-device yet.
- ⚠️ "OS sandbox" likely degrades silently on Android — no legal namespaces/seccomp-userland equivalent inside Termux (unverified).
- Proprietary — no public source repo found.

## Sources
- https://dev.meta.ai/docs/muse-code and https://llama.developer.meta.com/docs/muse-code (two independent Meta domains)
- https://dev.meta.ai/install.sh · https://api.meta.ai/muse-launcher.sh (fetched live 2026-10-20)
- `https://api.meta.ai/muse-code/channels/muse-stable` → 1.4.11-R6667.1; lookaside manifest (per-arch sha256)
- https://codersera.com/blog/how-to-install-muse-code-cli-2026 (⚠️ third-party; cross-verified by ELF probe) · https://musecodes.io/docs (⚠️ third-party docs; matches official) · https://github.com/mifunedev/agro/blob/main/docs/harnesses/muse-code.md (env-knob cross-check)
