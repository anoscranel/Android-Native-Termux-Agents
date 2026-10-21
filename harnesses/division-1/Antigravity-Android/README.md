# Antigravity (agy) on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Antigravity-Android/install.sh | bash
```

## What it is
`agy` — Google's Antigravity agentic coding CLI. A single ~203 MB glibc-linked Go ELF, not on npm. Two small mutations: `patchelf --set-rpath` to Termux's glibc, and a **one-instruction patch** rewriting `faccessat2` (syscall 439) → `faccessat` (48) — Android seccomp traps faccessat2 with SIGSYS and Go calls it unconditionally. Glibc-runner exec. Device-verified: `agy 1.1.25` (kernel 5.10 — blocker is seccomp policy, not kernel age).

## One-command install
The TL;DR line does it all: glibc runtime, checksummed payload, rpath patch, faccessat2 blob patch, wrapper. Idempotent — safe to re-run.

## Step-by-step
1. `pkg install -y patchelf zstd nodejs glibc-repo && pkg install -y glibc` → `$PREFIX/glibc/lib/ld-linux-aarch64.so.1`.
2. Download `agy.bin.zst` + `SHA256SUMS` from the payloads release (below; Antigravity 1.4.2), sha256-verify, `zstd -d` to `~/.local/bin/agy.bin`.
3. `patchelf --set-rpath $PREFIX/glibc/lib ~/.local/bin/agy.bin`
4. Blob patch: scan 4-byte-aligned offsets for `movz x0,#439` (`e0 36 80 d2`), rewrite to `movz x0,#48` (`00 06 80 d2`). Zero matches = loud failure, never silent success.
5. Wrapper `~/.local/bin/agy`: clears `LD_PRELOAD` (Bionic symbols must not leak into the glibc process), execs `ld-linux-aarch64.so.1 --library-path $PREFIX/glibc/lib agy.bin`.
6. Auth: `agy` runs Google OAuth — `termux-open-url` the printed URL; CLI polls. ⚠️ headless/device-code flag set unverified — check `agy auth --help`.

## Termux quirks & workarounds
- The glibc-runner pattern (`env -u LD_PRELOAD <ld.so> --library-path <glibc lib> <bin>`) is the canonical native method — no proot.
- On-device wrapper exports `HTTP(S)_PROXY=127.0.0.1:18080` wrapper-scoped and calls `~/bin/ensure-local-proxy.sh` if present (guarded, degrades gracefully). Newer wrappers drop the proxy — the glibc runner resolves DNS via Termux's patched `resolv.conf`. Both work.
- Phantom process killer / TMPDIR / tmux — see [Claude-Code-Android](../Claude-Code-Android/README.md).

## Limits
- Payload is a third-party checksummed binary — trust is your decision.
- Device-verified copy is 1.1.25; release carries 1.4.2, identical patch/wrapper layout. Patch site count asserted at install.

## Sources
- https://github.com/mrfandu1/patched-cli-payloads (release `payloads-v2`: `agy.bin.zst`, `SHA256SUMS`, `scripts/patch-agy-faccessat2.js`, `wrappers/agy`)
- https://man7.org/linux/man-pages/man2/faccessat2.2.html (faccessat2 added in Linux 5.8)
- Device autopsy (2026-10-20): `agy --version` → 1.1.25; `$PREFIX/glibc/lib/libc.so.6` present
