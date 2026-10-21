# Codex CLI on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — method runs on a real aarch64 Android phone (`codex-cli 0.154.0`); this script pins 0.162.0-alpha.10 and was not re-run there

> [!WARNING]
> This installer downloads a **patched, unofficial build** of the vendor's binary from the third-party repo [`mrfandu1/patched-cli-payloads`](https://github.com/mrfandu1/patched-cli-payloads). The vendor does not publish or endorse it, and that repo states no license. The script pins the payload's sha256, taken from the same release (trust on first use): it detects a changed file, not who built it. Read `install.sh` and check the vendor's terms before you run it.

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Codex-Cli-Android/install.sh | bash
```

## What it is
OpenAI's official coding-agent CLI (Rust core, npm `@openai/codex`). Upstream maps linux/aarch64 to the **static-musl** triple `aarch64-unknown-linux-musl`, and static binaries run on Bionic unchanged. Two steps are needed: put the vendor binaries where the launcher looks, and replace the npm shim (its `#!/usr/bin/env` shebang breaks on Termux) with a small Node launcher.

## One-command install
The TL;DR line installs Termux deps, the pinned npm package, the pinned static vendor binaries (sha256 hard-coded in the script) and the Node wrapper. Idempotent — safe to re-run.

## Step-by-step
1. `pkg install -y nodejs curl zstd`
2. `rm -f $PREFIX/bin/codex && npm install -g @openai/codex@0.162.0-alpha.10` (pinned to match the payload; the `rm` lets a re-run replace an old wrapper).
3. Put the static binaries in `vendor/aarch64-unknown-linux-musl/bin/{codex,codex-code-mode-host}` under `$PREFIX/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-arm64/`, plus a minimal `package.json`. Each payload is checked against its hard-coded sha256.
4. `rm -f $PREFIX/bin/codex` (npm made it a symlink to upstream `codex.js`), then write the Node wrapper there. It sets `SSL_CERT_FILE` and dynamic-imports upstream `bin/codex.js`. The script form keeps `process.argv` aligned and sets env before the Rust child starts.
5. `codex login --device-auth` → code + URL; `termux-open-url` it. State lives in `~/.codex`.

## Termux quirks & workarounds
- Static musl is the whole trick — the binary never needs Android's missing glibc.
- Optional loopback proxy: if `~/bin/ensure-local-proxy.sh` is installed and executable, the wrapper runs it and sets `HTTP(S)_PROXY=127.0.0.1:18080` for Codex only. Without it, proxy settings are left alone.
- Phantom process killer (~32 child processes, device-wide): use `tmux` and disable child-process restrictions in Developer Options.
- Don't delete `codex-code-mode-host`; the CLI starts it for code mode.

## Limits
- The vendor binaries are a third-party payload with no license. Their hashes were pinned from the release's own `SHA256SUMS` on 2026-10-21 (trust-on-first-use). A match with upstream's own musl build is ⚠️ unverified.
- Pure-upstream route (upstream's `@openai/codex@<ver>-linux-arm64` registry tarball in the same vendor path) is plausibly NATIVE — ⚠️ unverified.

## Sources
- https://github.com/mrfandu1/patched-cli-payloads (release `payloads-v2`; `codex.bin.zst`, `codex-code-mode-host.bin.zst`, `SHA256SUMS`)
- https://github.com/openai/codex
- npm registry `@openai/codex` (platform alias packages; standalone `@openai/codex-linux-arm64` returns 404)
