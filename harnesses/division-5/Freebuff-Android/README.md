# Freebuff on Termux (native Android, no proot)

**Verdict:** PATCHED-NATIVE · **Confidence:** high — device-verified 2026-10-20 (v0.0.149)

## TL;DR

Freebuff *does* install natively: download the official linux-arm64 tarball straight from Codebuff's release API, run the 138 MB glibc binary through `grun` (Termux's own native glibc-runner package — not proot). One command below; verified on a real phone.

## What it is

Freebuff is CodebuffAI's closed-source "free AI coding assistant" CLI (npm `freebuff@0.0.149`, homepage freebuff.com). The npm package is only a launcher; on first run it downloads a platform binary into `~/.config/manicode/` and execs it. That downloader platform-switch (`linux`/`darwin`/`win32`) forgets Android and prints `Unsupported platform: android arm64` — but the payload it fetches is a plain glibc linux-arm64 ELF, which Termux's glibc-repo can run directly.

## One-command install

```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-5/Freebuff-Android/install.sh | bash
```

## Step-by-step

1. `pkg update && pkg install glibc-repo && pkg install glibc glibc-runner tar curl`
2. `mkdir -p ~/.config/manicode`
3. `curl -fsSL -o "$TMPDIR/fb.tgz" https://codebuff.com/api/releases/download/0.0.149/freebuff-linux-arm64.tar.gz`
4. Verify: `echo "2641083e106b0594b365779833d03022933369b409e9116f332b644949f5c608  $TMPDIR/fb.tgz" | sha256sum -c -`
5. `tar -xzf "$TMPDIR/fb.tgz" -C ~/.config/manicode && chmod +x ~/.config/manicode/freebuff`
6. Wrapper `$PREFIX/bin/freebuff`:
   ```bash
   #!/data/data/com.termux/files/usr/bin/bash
   exec grun "$HOME/.config/manicode/freebuff" "$@"
   ```
7. `freebuff --version` → prints `0.0.149`. Then `freebuff login` (browser-token flow on the phone).

## Termux quirks & workarounds

- The npm launcher stays broken on Android; we skip it entirely and pull the tarball it would have fetched (same URL pattern it uses).
- `grun` (from `glibc-runner` pkg) handles the loader, library path *and* Termux's `LD_PRELOAD` clash (`libtermux-exec` must not be preloaded into a glibc process) — don't hand-roll `ld.so` calls, use `grun`.
- Version is pinned at `0.0.149` with a published sha256. `FREEBUFF_VERSION=<v> bash install.sh` moves you to any later version but **fails closed** (no hash to check) unless you also pass `FB_UNVERIFIED=1` to accept that explicitly.

## Limits

- Closed source, single-vendor lineage (npm + freebuff.com = one operator) — a trust decision.
- Smoke-tested: `--version` / full `--help` on-device. A complete `login → agent` session is not yet smoke-tested.
- New versions change the tarball hash; check it fresh before publishing any pin bump.

## Sources

- npm registry `freebuff@0.0.149` (verified 2026-10-20)
- https://freebuff.com ⚠️ vendor homepage, single-source
- Device autopsy + native run 2026-10-20 (launcher source read; payload executed on-device via `grun`)
