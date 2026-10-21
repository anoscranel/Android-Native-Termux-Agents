# Opencode on Termux (native Android, no proot)
**Verdict:** NATIVE · **Confidence:** high — device-verified 2026-10-20 (bionic NDK build: install, and a full agent turn against an OpenAI-compatible endpoint)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-4/Opencode-Android/install.sh | bash
```

## What it is
Opencode is SST/Anomaly's open-source terminal AI coding agent (`github.com/sst/opencode`, docs at opencode.ai). Upstream ships Bun-compiled glibc/musl binaries that don't run on Android's Bionic. The working native route today is the community **bionic build** `bd-loser/opencode-bionic`: compiled with NDK r27c against Bionic and packaged as a `.deb`. On-device proof: `opencode 1.18.22`, ELF aarch64, interpreter `/system/bin/linker64` — a real Bionic binary, no shim.

## One-command install
The TL;DR script resolves the **latest** `opencode-bionic` release via the GitHub API, downloads the `aarch64.deb`, verifies a checksum **if the release publishes one**, and installs it with `apt` (which pulls dependencies). It follows the latest release by default; pin with `OPENCODE_VERSION=1.18.22`. ⚠️ Third-party build: the maintainer is not SST/Anomaly, so installing it is a trust decision.

## Step-by-step
The script automates this:

```bash
curl -fsSL <release-asset-url>/opencode_<ver>_aarch64.deb -o "$TMPDIR/opencode.deb"
apt install -y "$TMPDIR/opencode.deb"
opencode --version
```

⚠️ The asset name pattern (`opencode_<ver>_aarch64.deb`) may change; the script finds the asset through the GitHub API instead of guessing.

## Termux quirks & workarounds
- Phantom process killer: Android caps child processes at ~32 device-wide, whatever libc they use — this Bionic build and every shell command it starts count too. Run long sessions in `tmux` and disable child-process restrictions in Developer Options.
- TMPDIR: the bionic build runs clean with the stock Termux environment.
- Auth: `opencode auth login` works on the phone — the browser opens on the same device and the localhost callback reaches Termux.
- Fallback (PATCHED-NATIVE, if the bionic build lags): `npm i -g opencode-ai`, then patchelf the upstream Bun binary onto Alpine musl under `$PREFIX/lib/musl`, behind a wrapper. If musl DNS fails, that wrapper can set a loopback proxy (`127.0.0.1:18080`), but only when a proxy supervisor is installed. **Never** export that proxy shell-wide — if it dies, every `curl` breaks.

## Limits
- Third-party build: release cadence and trust belong to the maintainer, not upstream. No independent audit of the binary exists.
- The musl fallback is a documented method, not a shipped script; expert-only.

## Sources
- https://opencode.ai/docs/ (official install)
- https://github.com/sst/opencode
- https://github.com/bd-loser/opencode-bionic (third-party bionic build, checked via GitHub API 2026-10-20)
