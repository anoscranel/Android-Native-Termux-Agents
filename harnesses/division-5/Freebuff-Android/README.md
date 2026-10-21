# Freebuff on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — device-verified 2026-10-20 (v0.0.149)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-5/Freebuff-Android/install.sh | bash && freebuff --version
```

## What it is
Freebuff is CodebuffAI's closed-source "free AI coding assistant" CLI (npm `freebuff@0.0.149`, homepage freebuff.com). The npm package is only a launcher: on first run it downloads a platform binary into `~/.config/manicode/` and runs it. Its platform switch (`linux`/`darwin`/`win32`) has no Android case and prints `Unsupported platform: android arm64`. The binary it would fetch is a plain glibc linux-arm64 ELF, which Termux's glibc-repo runs through `grun` (Termux's own glibc runner).

## One-command install
The TL;DR script downloads the official 138 MB linux-arm64 tarball from Codebuff's release API, checks it against a sha256 pinned in the script, extracts it, writes a `grun` wrapper and deletes the tarball. Idempotent — safe to re-run.

## Step-by-step
1. `pkg update && pkg install glibc-repo && pkg install glibc glibc-runner tar curl`
2. `mkdir -p ~/.config/manicode`
3. `curl -fsSL -o "$TMPDIR/fb.tgz" https://codebuff.com/api/releases/download/0.0.149/freebuff-linux-arm64.tar.gz`
4. Verify: `echo "2641083e106b0594b365779833d03022933369b409e9116f332b644949f5c608  $TMPDIR/fb.tgz" | sha256sum -c -`
5. `tar -xzf "$TMPDIR/fb.tgz" -C ~/.config/manicode && chmod +x ~/.config/manicode/freebuff && rm "$TMPDIR/fb.tgz"`
6. Wrapper `$PREFIX/bin/freebuff` (remove any old file or symlink there first):
   ```bash
   #!/data/data/com.termux/files/usr/bin/bash
   exec grun "$HOME/.config/manicode/freebuff" "$@"
   ```
7. `freebuff --version` → prints `0.0.149`. Then `freebuff login` (browser-token flow on the phone).

## Termux quirks & workarounds
- The npm launcher stays broken on Android; this route skips it and pulls the tarball it would have fetched (same URL pattern).
- `grun` (from the `glibc-runner` package) handles the loader, the library path *and* Termux's `LD_PRELOAD` clash (`libtermux-exec` must not load into a glibc process). Use `grun` rather than hand-rolled `ld.so` calls.
- Version is pinned at `0.0.149` with a known sha256. `FREEBUFF_VERSION=<v> bash install.sh` moves to another version but **fails closed** (no hash to check) unless you also pass `FB_UNVERIFIED=1`.
- Phantom process killer (~32 child processes, device-wide): use `tmux` and disable child-process restrictions in Developer Options.

## Limits
- Closed source, one operator behind both npm and freebuff.com — a trust decision.
- Tested to `--version` and full `--help` on-device. A complete `login → agent` session was not tested.
- New versions change the tarball hash; check it fresh before bumping the pin.

## Sources
- npm registry `freebuff@0.0.149` (checked 2026-10-20)
- https://freebuff.com ⚠️ vendor homepage, single-source
- On-device check 2026-10-20 (launcher source read; payload run on-device via `grun`)
