# Grok Build on Termux (native Android, no proot)
**Verdict:** NATIVE · **Confidence:** high — device-verified 2026-10-20 (`grok 1.0.62 --version` ran natively, static aarch64 ELF)

## TL;DR
```bash
curl -fsSL https://x.ai/cli/install.sh | bash
```

## What it is
xAI's official terminal coding agent (`grok`): full-screen TUI, edits files, runs shell commands. Open source (Apache-2.0, Rust) — `xai-org/grok-build`. Its `linux-aarch64` release is a **statically linked aarch64 ELF** (byte-verified via range probe: no `INTERP` segment), so it should run under Bionic unchanged.

⚠️ Not to be confused with the community Grok CLI (`superagent-ai/grok-cli`, npm `grok-dev`): unaffiliated with xAI, ships **no linux-arm64 build** → NOT-VIABLE here. Both install a `grok` binary and overwrite each other.

## One-command install
The TL;DR line is the official installer. Installs `~/.grok/bin/{grok,agent}` (binary at `~/.grok/downloads/grok-linux-aarch64`). Pin a version: `curl -fsSL https://x.ai/cli/install.sh | bash -s 1.0.62` (channel `stable` → 1.0.62, 2026-10-20).

## Step-by-step
1. `pkg install -y curl` — the only requirement (`wget` also accepted).
2. Run the installer. Its `uname` cases match Termux: `Linux` → `linux`, `aarch64` → `aarch64`. It fetches `https://x.ai/cli/grok-<ver>-linux-aarch64` (fallback host `https://storage.googleapis.com/grok-build-public-artifacts/cli`) and safety-checks `"$tmp" --version` first — passes because the ELF is static.
3. Auth: `grok login --device-auth` (writes `~/.grok/auth.json`), or `GROK_DEPLOYMENT_KEY` to skip the browser (good over SSH). `GROK_CHANNEL=alpha|enterprise` picks non-stable channels.

## Termux quirks & workarounds
- **Installer side effects** (device-verified): creates `~/.grok/bin/{grok,agent}` symlinks, downloads into `~/.grok/downloads/grok-linux-aarch64`, and **appends an `export PATH` line to `~/.bashrc`**. Set `GROK_BIN_DIR` (e.g. `GROK_BIN_DIR=$PREFIX/bin curl … | bash`) to skip both.
- **Name collisions:** community `grok-cli` also claims `grok`; Cursor also installs `agent` (`~/.local/bin/agent`). PATH order decides; `command -v agent` for truth.
- Auth: `grok login --device-auth` (writes `~/.grok/auth.json`); `GROK_DEPLOYMENT_KEY` skips the browser (SSH-friendly). `termux-open-url` for the URL.
- Phantom process killer / TMPDIR / tmux — see [Claude-Code-Android](../Claude-Code-Android/README.md).

## Limits
- Device-verified only to `--version` and help output on 2026-10-20 (static-linked, no dlopen risk surface seen). Full agent loop never exercised; a seccomp-trapped syscall (known offender: `faccessat2`) can SIGSYS mid-run — none observed. Standing repair if it ever appears: the blob patch in [Antigravity-Android](../Antigravity-Android/README.md).
- Untested fallback: build from public Rust source (`pkg install rust`; toolchain via `rust-toolchain.toml`) — a legitimate NATIVE route.

## Sources
- https://github.com/xai-org/grok-build (Apache-2.0; README install block)
- https://x.ai/cli/install.sh (fetched live 2026-10-20: auth order `GROK_DEPLOYMENT_KEY`→`auth.json`; os/arch arms; BIN_DIR layout)
- https://x.ai/cli/stable → 1.0.62; `https://x.ai/cli/grok-1.0.62-linux-aarch64` → static ELF (probed 2026-10-20)
- https://cosyra.com/guides/grok-cli-vs-grok-build.html (⚠️ secondary single source)
- https://dev.to/andrew-ooo/grok-cli-review-the-community-grok-coding-agent-2026-4c1f (disambiguation cross-check)
