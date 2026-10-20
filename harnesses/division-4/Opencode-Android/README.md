# Opencode on Termux (native Android, no proot)

**Verdict:** NATIVE · **Confidence:** high — device-verified 2026-10-20 (bionic NDK build, install, and a full agent turn against an OpenAI-compatible endpoint)

## TL;DR

```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-4/Opencode-Android/install.sh | bash
```

## What it is

Opencode is SST/Anomaly's open-source terminal AI coding agent (`github.com/sst/opencode`, docs at opencode.ai). Upstream ships Bun-compiled glibc/musl single binaries that don't run on Android's Bionic. The working native route today is the community **bionic build** `bd-loser/opencode-bionic` — compiled with NDK r27c against Bionic, installed as a dpkg package. On-device proof: `opencode 1.18.22`, ELF aarch64, `interpreter /system/bin/linker64` — a genuine Bionic binary, no shim.

## One-command install

`install.sh` (TL;DR) resolves the latest `opencode-bionic` release via the GitHub API, downloads the `aarch64.deb`, verifies a checksum **if the release publishes one**, and installs with `dpkg`. Pin a version with `OPENCODE_VERSION=1.18.22`. ⚠️ Third-party build: installing community-compiled binaries is a trust decision — the maintainer is not SST/Anomaly.

## Step-by-step

The script only automates this:

```bash
curl -fsSL <release-asset-url>/opencode_<ver>_aarch64.deb -o opencode.deb
dpkg -i opencode.deb
opencode --version
```

⚠️ Asset naming (`opencode_<ver>_aarch64.deb`) comes from the source findings; the script resolves it via the GitHub API.

## Termux quirks & workarounds

- Phantom-killer problem applies to musl/glibc binaries, **not** this NDK build — it speaks Bionic directly.
- TMPDIR: the bionic build runs clean with stock Termux env.
- Auth: `opencode auth login` works on the phone — the browser tab opens on the same device and the localhost callback reaches Termux.
- Fallback (PATCHED-NATIVE, if the bionic build lags): `npm i -g opencode-ai` + upstream Bun binary patchelfed onto Alpine musl under `$PREFIX/lib/musl`, behind a wrapper exporting a loopback proxy (`127.0.0.1:18080`) for musl-vs-bionic DNS edge cases. **Never** export that proxy shell-wide — if it dies, every curl breaks.

## Limits

- Third-party build: release cadence and trust are the maintainer's, not upstream's. No independent audit of the binary exists.
- The musl fallback is a documented method, not a shipped script; expert-only.

## Sources

- https://opencode.ai/docs/ (official install)
- https://github.com/sst/opencode
- https://github.com/bd-loser/opencode-bionic (third-party bionic build, verified via GitHub API 2026-10-20)
