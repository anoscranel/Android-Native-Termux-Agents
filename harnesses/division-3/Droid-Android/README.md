# Droid on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — device-verified 2026-10-20 (`droid --version` → `0.245.0` ran natively)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-3/Droid-Android/install.sh | bash
```

## What it is
Factory AI's terminal agent **Droid** (`droid`) — a TUI plus scriptable `droid exec` (CI/automation, JSON output, session continuation, worktree modes). Auth via browser device flow and a Factory account. It ships a real linux-arm64 binary (ELF aarch64, glibc dynamic), which runs through Termux's own **grun** glibc runner.

## One-command install
The TL;DR line installs the glibc runtime, downloads the pinned `0.245.0` binary, checks it against the vendor's sha256 sidecar, and writes a wrapper. Idempotent — a `.version` stamp skips the download when the version is unchanged. `DROID_VERSION=<v>` moves to another release (still sidecar-verified); `DROID_FORCE=1` re-downloads.

## Step-by-step
1. `pkg install glibc-repo && pkg install glibc glibc-runner curl` — grun handles the loader, library path and preload cleanup.
2. Download the pinned release and check its sidecar:
   ```bash
   VER=0.245.0
   curl -fsSLO "https://downloads.factory.ai/factory-cli/releases/${VER}/linux/arm64/droid"
   curl -fsSLO "https://downloads.factory.ai/factory-cli/releases/${VER}/linux/arm64/droid.sha256"
   echo "$(awk '{print $1}' droid.sha256)  droid" | sha256sum --check
   chmod +x droid && mkdir -p "$PREFIX/opt/droid" && mv droid "$PREFIX/opt/droid/droid"
   ```
3. Wrapper `$PREFIX/bin/droid`: `exec grun $PREFIX/opt/droid/droid "$@"`.
4. Run `droid` inside a git repo; finish the browser device auth.

Vendor alternatives: `curl -fsSL https://app.factory.ai/cli | sh` or `npm install -g droid`. The path above stays version-pinned; prefer it.

## Termux quirks & workarounds
- **~287 MB single binary.** Run it under `tmux` + `termux-wake-lock`, and disable battery optimization for Termux.
- Phantom process killer (~32 child processes, device-wide): disable child-process restrictions in Developer Options.
- A raw `ld.so --library-path` call fails on the 2026 glibc package (`libc.so: invalid ELF header` — that file is a text linker script). **grun is the fix.** Devin and Cursor use it too; `agy` keeps its raw ld.so call because that one is device-proven.
- `droid exec` is the phone-friendly headless mode — pair it with `tmux send-keys`.
- `downloads.factory.ai` needs no auth.

## Limits
- Only a sha256 sidecar from the same server, no signature.
- Device-verified to `--version`; long interactive sessions remain exposed to the phantom process killer.

## Sources
- https://docs.factory.ai/droid-cli/cli-reference
- https://github.com/factory-ai/factory
- https://registry.npmjs.org/droid
- Device verification 2026-10-20 (aarch64 Android phone): `droid --version` → `0.245.0` via grun
