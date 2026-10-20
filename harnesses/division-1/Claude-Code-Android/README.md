# Claude Code on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Claude-Code-Android/install.sh | bash
```

## What it is
Anthropic's official terminal agent (npm `@anthropic-ai/claude-code`). Since v2.1.113 the real binary is a glibc-linked Bun build Bionic can't run (2.1.112 was the last vanilla release). Fix: swap in a musl binary and `patchelf` its ELF interpreter to musl. Device-verified: `claude 2.1.295`.

## One-command install
The TL;DR line installs: Termux deps, checksummed Alpine musl runtime, pinned npm package, checksummed musl `claude` binary, patchelf patch, wrapper. Idempotent — safe to re-run.

## Step-by-step
1. `pkg install -y nodejs zstd patchelf tar curl`
2. Extract Alpine v3.24 aarch64 APKs (`musl`, `libgcc`, `libstdc++`) into `$HOME/.local` and `$PREFIX/lib/musl`.
3. `npm install -g @anthropic-ai/claude-code@2.1.288` — its `$PREFIX/bin/claude` stays a broken stub.
4. Download `claude.bin.zst` + `SHA256SUMS` from the mrfandu1 payloads release, sha256-verify, `zstd -d` to `~/.local/bin/claude-bin`.
5. `patchelf --set-interpreter $HOME/.local/lib/ld-musl-aarch64.so.1 --set-rpath $HOME/.local/lib:$PREFIX/lib/musl/lib:$PREFIX/lib/musl/usr/lib` on `claude-bin`.
6. Wrapper `~/.local/bin/claude`: `DISABLE_AUTOUPDATER=1`, clears `LD_PRELOAD`, execs `claude-bin`.
7. PATH: `$HOME/.local/bin` must precede `$PREFIX/bin`.

## Termux quirks & workarounds
- Phantom process killer (~32 child procs device-wide) kills subagents — disable child-process restrictions in Developer Options.
- TMPDIR: keep scratch in `$PREFIX/tmp`; `/tmp` is unwritable.
- `DISABLE_AUTOUPDATER=1` mandatory — updater re-downloads the broken glibc binary.
- Auth: `claude` prints a localhost OAuth URL — `termux-open-url` it, approve in browser. Login state `~/.claude` never touched.
- If network fails: loopback proxy `127.0.0.1:18080`, **wrapper-scope only** — never shell-wide (dead supervisor breaks `curl`).

## Limits
- Native binary is a third-party build (checksums published in payloads repo). Trust is your decision.
- ≥4 GB RAM recommended; Node 18–24 (⚠️ single-source community claims).
- APKs pinned; findings publish no APK sha256 — script verifies gzip integrity, prints hashes. ⚠️

## Sources
- https://github.com/mrfandu1/patched-cli-payloads (release `payloads-v2`, Claude Code 2.1.288)
- https://www.npmjs.com/package/@anthropic-ai/claude-code
- https://cosyra.com/guides/claude-code-termux-fix.html (⚠️ via vault)
- https://github.com/ferrumclaudepilgrim/claude-code-android/blob/main/TROUBLESHOOTING.md (⚠️ via vault)
