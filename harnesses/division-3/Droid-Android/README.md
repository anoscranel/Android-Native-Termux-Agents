# Droid on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — device-verified 2026-10-20 (`droid --version` → `0.245.0` ran natively)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-3/Droid-Android/install.sh | bash
```

## What it is
Factory AI's terminal agent **Droid** (`droid`) — TUI plus scriptable `droid exec` (CI/automation, JSON output, session continuation, worktree modes). Auth via browser device flow + Factory account. Ships a real linux-arm64 binary: ELF aarch64, glibc dynamic → runs via Termux's own **grun** glibc runner, version-pinned + sha256-verified.

## Step-by-step (as the oneliner does it)
1. `pkg install glibc-repo && pkg install glibc glibc-runner curl` — grun handles loader + library path + preload-sanitize.
2. Download the pinned release with sidecar verification:
   ```bash
   VER=0.245.0
   curl -fsSLO "https://downloads.factory.ai/factory-cli/releases/${VER}/linux/arm64/droid"
   curl -fsSLO "https://downloads.factory.ai/factory-cli/releases/${VER}/linux/arm64/droid.sha256"
   echo "$(awk '{print $1}' droid.sha256)  droid" | sha256sum --check
   chmod +x droid && mkdir -p "$PREFIX/opt/droid" && mv droid "$PREFIX/opt/droid/droid"
   ```
3. Wrapper `$PREFIX/bin/droid`: `exec grun $PREFIX/opt/droid/droid "$@"`.
4. Run `droid` inside a git repo; complete the browser device auth.

Vendor alternatives: `curl -fsSL https://app.factory.ai/cli | sh` or `npm install -g droid` — the scripted path above stays checksum-pinned; prefer it.

## Termux quirks & workarounds
- **~287 MB single binary** (Bun/SEA-style) — always run under `tmux` + `termux-wake-lock`; disable battery optimization for Termux (Android phantom process killer).
- Raw `ld.so --library-path` fails on the 2026 glibc SDK (`libc.so: invalid ELF header` — SDK ships an ASCII ld-script). **grun is the fix.** Same fix in this repo's Devin/Cursor installers; `agy` keeps its raw-ld.so pattern because that one is device-proven.
- `droid exec` is the phone-friendly headless mode — pair with `tmux send-keys`.
- `downloads.factory.ai` needs no auth. Keep the version PINNED; verify the sidecar at each bump.

## Limits
- Only a sha256 sidecar, no signature.
- Device-verified to `--version`; long interactive TUI sessions remain subject to phantom-killer realities.

## Sources
- https://docs.factory.ai/droid-cli/cli-reference
- https://github.com/factory-ai/factory
- https://registry.npmjs.org/droid
- Device verification 2026-10-20 (this author's aarch64 Android phone): `droid --version` → `0.245.0` via grun
