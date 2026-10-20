# Cursor `cursor-agent` on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — device-verified 2026-10-20 (`2026.10.19-6bbf2c4 --version` ran natively)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Cursor-Android/install.sh | bash
```

## What it is
Cursor's official terminal agent: repo-aware CLI, interactive + headless (`-p`). Compiled Node-SEA binaries, no npm package. Primary command `agent`; alias `cursor-agent`. All-glibc payload (node + SEA binaries + 20 `*.linux-arm64-gnu.node` addons), run via Termux's own **grun** glibc runner.

## One-command install
The TL;DR line runs Cursor's official installer, then swaps the symlinks for grun wrappers and retargets a glibc loader on the four glibc children. Idempotent — re-heals after Cursor updates.

## Step-by-step
1. `pkg install -y curl patchelf glibc-repo && pkg install -y glibc glibc-runner`
2. The official installer (`curl https://cursor.com/install -fsS | bash`) detects Termux correctly — version-stamped layout under `~/.local/share/cursor-agent/versions/<v>/`, stock symlinks `~/.local/bin/{agent,cursor-agent}`.
3. `cursor-agent` is a **bash SEA launcher**, not the executable — it execs `$SCRIPT_DIR/node index.js`. grun the node child directly.
4. But the launcher itself spawns **glibc child binaries**; Node resolves them via `execve` — patch their PT_INTERP: `patchelf --set-interpreter $PREFIX/glibc/lib/ld-linux-aarch64.so.1` on `node`, `cursor-agent-sea`, `cursor-agent-worker-sea`, `cursorsandbox`. (Not needed for renamed children — works as-is: their dlopen'ed `.node` addons are glibc, fine.)
5. Wrappers: `exec grun $latest/node $latest/index.js "$@"`, shadow the stock symlinks.
6. Auth: `cursor-agent login` (browser — `termux-open-url` the URL) or a dashboard API key for headless.

## Termux quirks & workarounds
- **`agent` name collision:** Grok Build also installs `agent` (`~/.grok/bin/agent`). PATH order decides — prefer `cursor-agent`.
- Raw `ld.so --library-path` fails on the 2026 glibc SDK (`libc.so: invalid ELF header` — SDK ships an ASCII ld-script); **grun handles it**. Same fix batch for Droid/Devin.
- Patchelf step is one-time per version; the updater lands new unpatched dirs — re-run this installer to re-patch.
- Phantom process killer / TMPDIR / tmux — see [Claude-Code-Android](../Claude-Code-Android/README.md).

## Limits
- SEA child-spawn is respawn rather than full-plugin smoke-tested; tested to `--version`, resumable session, attached login TTY.
- If Cursor changes the launcher shape, the installer's discover-then-patch step fails informatively.
- Falls back to nothing — no proot/cloud mates, per the repo's hard constraint.

## Sources
- https://cursor.com/install (official installer; versioned layout, symlinks)
- https://cursor.com/docs/cli/installation
- Device verification 2026-10-20 (this author's aarch64 Android phone): `cursor-agent --version` → `2026.10.19-6bbf2c4` via the grun+patchelf flow
