# Claude Code on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — method runs on a real aarch64 Android phone (`claude 2.1.295`); this script pins payload 2.1.288 and was not re-run there

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Claude-Code-Android/install.sh | bash
```

## What it is
Anthropic's official terminal agent (npm `@anthropic-ai/claude-code`). Since v2.1.113 the real binary is a glibc-linked Bun build that Bionic can't run (2.1.112 was the last plain release). The fix: swap in a musl build and point its ELF interpreter at a musl loader with `patchelf`.

## One-command install
The TL;DR line installs Termux deps, a pinned and sha256-verified Alpine musl runtime, the pinned npm package, a pinned and sha256-verified musl `claude` binary, the patchelf fix, and a wrapper. Idempotent — safe to re-run. `FORCE=1` re-downloads the binary.

## Step-by-step
1. `pkg install -y nodejs zstd patchelf tar curl`
2. Download Alpine v3.24 aarch64 APKs (`musl`, `libgcc`, `libstdc++`), check each sha256, extract into `$HOME/.local` and `$PREFIX/lib/musl` (Alpine metadata files skipped).
3. `npm install -g @anthropic-ai/claude-code@2.1.288` — its `$PREFIX/bin/claude` stays a broken stub.
4. Download `claude.bin.zst` from the payloads release (below), check it against the sha256 hard-coded in the script, `zstd -d` to `~/.local/bin/claude-bin`.
5. `patchelf --set-interpreter $HOME/.local/lib/ld-musl-aarch64.so.1 --set-rpath $HOME/.local/lib:$PREFIX/lib/musl/lib:$PREFIX/lib/musl/usr/lib` on `claude-bin`.
6. Wrapper `~/.local/bin/claude`: `DISABLE_AUTOUPDATER=1`, clears `LD_PRELOAD`, execs `claude-bin`. Any existing file or symlink there is removed first.
7. PATH: `$HOME/.local/bin` must come before `$PREFIX/bin`.

## Termux quirks & workarounds
- Phantom process killer (~32 child processes, device-wide) kills subagents. Use `tmux` and disable child-process restrictions in Developer Options.
- TMPDIR: keep scratch in `$PREFIX/tmp`; `/tmp` is not writable.
- `DISABLE_AUTOUPDATER=1` is required — the updater re-downloads the broken glibc binary.
- Auth: `claude` prints a localhost OAuth URL — `termux-open-url` it and approve in the browser. The script never touches `~/.claude`.

## Limits
- The native binary is a third-party rebuild with no license. Its hash was pinned from the release's own `SHA256SUMS` on 2026-10-21 (trust-on-first-use): it catches a changed file, not a bad first build. Running it may breach the vendor's terms; that is your decision.
- ≥4 GB RAM recommended; Node 18–24 (⚠️ single-source community claims).

## Sources
- https://github.com/mrfandu1/patched-cli-payloads (release `payloads-v2`, Claude Code 2.1.288)
- https://www.npmjs.com/package/@anthropic-ai/claude-code
- https://dl-cdn.alpinelinux.org/alpine/v3.24/main/aarch64/
- https://cosyra.com/guides/claude-code-termux-fix.html (⚠️ secondary)
- https://github.com/ferrumclaudepilgrim/claude-code-android (⚠️ community troubleshooting)
