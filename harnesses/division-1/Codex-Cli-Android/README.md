# Codex CLI on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-1/Codex-Cli-Android/install.sh | bash
```

## What it is
OpenAI's official coding-agent CLI (Rust core, npm `@openai/codex`). Upstream already maps linux/aarch64 to the **static-musl** triple `aarch64-unknown-linux-musl`, and static binaries run on Bionic unmodified. The only surgery: place the vendor binaries where the launcher looks, and replace the npm shim (its `#!/usr/bin/env` pathing breaks) with a tiny Node launcher. Device-verified: `codex-cli 0.154.0`.

## One-command install
The TL;DR line does it all: Termux deps, pinned npm package, checksummed static vendor binaries, Node wrapper. Idempotent — safe to re-run.

## Step-by-step
1. `pkg install -y nodejs curl zstd`
2. `npm install -g @openai/codex@0.162.0-alpha.10` (pinned to match payload).
3. Drop static binaries into `vendor/aarch64-unknown-linux-musl/bin/{codex,codex-code-mode-host}` under `$PREFIX/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-arm64/`, plus a minimal `package.json`. Payloads sha256-verified against release `SHA256SUMS`.
4. Overwrite `$PREFIX/bin/codex` with the Node wrapper: sets `HTTP(S)_PROXY=http://127.0.0.1:18080`, `NO_PROXY`, `SSL_CERT_FILE`, then dynamic-imports upstream `bin/codex.js` (script form keeps `process.argv` aligned and exports env before the Rust child spawns).
5. `codex login --device-auth` → code + URL; `termux-open-url` it. State in `~/.codex`.

## Termux quirks & workarounds
- Static musl is the whole trick — the binary ignores Android's missing glibc entirely.
- Loopback proxy is wrapper-scoped, never shell-wide. ⚠️ The wrapper expects the `127.0.0.1:18080` supervisor (`~/bin/ensure-local-proxy.sh`) from the full mrfandu1 installer (`proxy/` dir); without it network calls hang — fetch the supervisor or delete the three proxy lines from `$PREFIX/bin/codex`.
- Phantom process killer (~32 procs) + TMPDIR inside Termux home — see [Claude-Code-Android](../Claude-Code-Android/README.md).
- Don't delete `codex-code-mode-host`; the CLI spawns it for code mode.

## Limits
- Vendor binaries are a third-party checksummed payload; match to upstream's own musl build ⚠️ unverified. Trust is your decision.
- Pure-upstream DIY (npm + upstream's `@openai/codex@<ver>-linux-arm64` registry tarball into the same vendor path) is plausibly NATIVE — ⚠️ unverified.

## Sources
- https://github.com/mrfandu1/patched-cli-payloads (release `payloads-v2`; `codex.bin.zst`, `codex-code-mode-host.bin.zst`, `SHA256SUMS`)
- https://github.com/openai/codex
- npm registry `@openai/codex` (0.163.0; platform alias packages — standalone `@openai/codex-linux-arm64` 404s)
