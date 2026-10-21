# Cursor `cursor-agent` on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — device-verified 2026-10-20 (`2026.10.19-6bbf2c4 --version` ran natively)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Cursor-Android/install.sh | bash
```

## What it is
Cursor's official terminal agent: repo-aware CLI, interactive and headless (`-p`). Compiled Node SEA binaries, no npm package. Primary command `agent`; alias `cursor-agent`. The whole payload is glibc (node, helper binaries, 20 `*.linux-arm64-gnu.node` addons), so it runs through Termux's own **grun** glibc runner.

## One-command install
The TL;DR line runs Cursor's official installer, points the glibc helpers at Termux's loader, and replaces the stock symlinks with grun wrappers. ⚠️ Cursor's installer is not pinned and not hash-verified: it always installs the latest build. Idempotent — re-run after Cursor updates.

## Step-by-step
1. `pkg install -y curl patchelf glibc-repo && pkg install -y glibc glibc-runner`
2. `curl https://cursor.com/install -fsS | bash` — detects linux/arm64; installs to `~/.local/share/cursor-agent/versions/<v>/` with symlinks `~/.local/bin/{agent,cursor-agent}`.
3. `cursor-agent` is a bash launcher that runs `$SCRIPT_DIR/node index.js`. Run that node directly with grun.
4. `index.js` starts sibling glibc executables directly. Their ELF interpreter points to a path Android lacks, so set it: `patchelf --set-interpreter $PREFIX/glibc/lib/ld-linux-aarch64.so.1` on `node` and each helper binary. The `.node` addons are libraries loaded by the patched node; they need no change.
5. Wrappers: `exec grun $latest/node $latest/index.js "$@"`, replacing the stock symlinks. `~/.local/bin/agent` is replaced only if it points into Cursor's versions dir.
6. Auth: `cursor-agent login` (browser — `termux-open-url` the URL), or an API key from the Cursor web console for headless use.

## Termux quirks & workarounds
- **`agent` name clash:** Grok Build installs its own `agent` in `~/.grok/bin`. PATH order decides — prefer `cursor-agent`.
- A raw `ld.so --library-path` call fails on the 2026 glibc package (`libc.so: invalid ELF header` — that file is a text linker script); **grun handles it**. Devin and Droid use the same fix.
- Cursor's updater adds new, unpatched version dirs — re-run the installer to patch them.
- Phantom process killer (~32 child processes, device-wide): use `tmux` and disable child-process restrictions in Developer Options.

## Limits
- Tested to `--version`, a resumed session and an interactive login. Helper processes started during a long task were not exercised.
- If Cursor changes its layout, the installer stops with a clear error.
- No fallback route: proot and remote machines are out of scope here.

## Sources
- https://cursor.com/install (official installer; versioned layout, symlinks)
- https://cursor.com/docs/cli/installation
- Device verification 2026-10-20 (aarch64 Android phone): `cursor-agent --version` → `2026.10.19-6bbf2c4` via grun + patchelf
