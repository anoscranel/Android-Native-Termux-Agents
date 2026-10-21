# Antigravity (agy) on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — method runs on a real aarch64 Android phone (`agy 1.1.25`); this script pins payload 1.4.2 and was not re-run there

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Antigravity-Android/install.sh | bash
```

## What it is
`agy` — Google's Antigravity agentic coding CLI. A single ~203 MB glibc-linked Go ELF, not on npm. Two small changes make it run: `patchelf --set-rpath` to Termux's glibc, and a **one-instruction patch** that rewrites `faccessat2` (syscall 439) to `faccessat` (48). Android's seccomp policy traps `faccessat2` with SIGSYS, and Go calls it unconditionally. The blocker is seccomp policy, not kernel age.

## One-command install
The TL;DR line installs the glibc runtime, the pinned payload (sha256 hard-coded in the script), the rpath fix, the faccessat2 patch and a wrapper. Idempotent — safe to re-run.

## Step-by-step
1. `pkg install -y patchelf zstd nodejs curl glibc-repo && pkg install -y glibc` → `$PREFIX/glibc/lib/ld-linux-aarch64.so.1`.
2. Download `agy.bin.zst` from the payloads release (below; Antigravity 1.4.2), check it against the hard-coded sha256, `zstd -d` to `~/.local/bin/agy.bin`.
3. `patchelf --set-rpath $PREFIX/glibc/lib ~/.local/bin/agy.bin`
4. Blob patch: scan 4-byte-aligned offsets for `movz x0,#439` (`e0 36 80 d2`) and rewrite to `movz x0,#48` (`00 06 80 d2`). The script prints the site count and aborts on zero. Set `AGY_EXPECTED_SITES=<n>` to require an exact count.
5. Wrapper `~/.local/bin/agy`: clears `LD_PRELOAD` (Bionic symbols must not leak into the glibc process), then runs `ld-linux-aarch64.so.1 --library-path $PREFIX/glibc/lib agy.bin` directly (no `grun`).
6. Auth: `agy` runs Google OAuth — `termux-open-url` the printed URL; the CLI polls. ⚠️ A headless/device-code flag is unverified — check `agy auth --help`.

## Termux quirks & workarounds
- Optional loopback proxy: if `~/bin/ensure-local-proxy.sh` is installed and executable, the wrapper runs it and sets `HTTP(S)_PROXY=127.0.0.1:18080` for agy only. Without it, proxy settings are left alone; agy then resolves DNS through Termux's glibc `resolv.conf`.
- Phantom process killer (~32 child processes, device-wide): use `tmux` and disable child-process restrictions in Developer Options.

## Limits
- The payload is a third-party rebuild with no license. Its hash was pinned from the release's own `SHA256SUMS` on 2026-10-21 (trust-on-first-use). Running it may breach the vendor's terms; that is your decision.
- The phone runs agy 1.1.25; the release carries 1.4.2 with the same patch and wrapper layout.

## Sources
- https://github.com/mrfandu1/patched-cli-payloads (release `payloads-v2`: `agy.bin.zst`, `SHA256SUMS`, `scripts/patch-agy-faccessat2.js`)
- https://man7.org/linux/man-pages/man2/faccessat2.2.html (faccessat2 added in Linux 5.8)
- On-device check (2026-10-20): `agy --version` → 1.1.25; `$PREFIX/glibc/lib/libc.so.6` present
