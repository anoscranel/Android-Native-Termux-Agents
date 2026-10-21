# Devin on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — device-verified 2026-10-20 (`devin 3000.11.92` ran natively)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-3/Devin-Android/install.sh | bash
```

## What it is
Cognition's local CLI **Devin for Terminal** (`devin`) — a command-line coding agent, separate from cloud Devin, with `/handoff` to move a task to the cloud. Local tools: Bash/Read/Write/Edit/Glob/Grep/WebFetch/WebSearch. It ships as a glibc aarch64 tarball and runs through Termux's own **grun** glibc runner.

## One-command install
The TL;DR line installs the glibc runtime, reads the vendor manifest, downloads and sha256-checks the current tarball, and writes a wrapper. Idempotent — a `.version` stamp skips the download when nothing changed (`DEVIN_FORCE=1` re-downloads). Version floats: it follows the vendor's current manifest.

Pin an exact tarball: set **both** `DEVIN_URL=<tarball>` and `DEVIN_SHA256=<hash>`. The script refuses `DEVIN_URL` without `DEVIN_SHA256`.

## Step-by-step
1. `pkg install glibc-repo && pkg install glibc glibc-runner curl python` — grun handles the loader, library path and preload cleanup.
2. Read `https://static.devin.ai/cli/current/manifest.json` → version, URL and **published sha256**.
3. Download the tarball into `$PREFIX/opt/devin`, verify the hash, extract there (`bin/devin` + `share/`), delete the tarball.
4. Wrapper `$PREFIX/bin/devin`: `exec grun $PREFIX/opt/devin/bin/devin "$@"`.
5. Auth: `DEVIN_API_KEY=...` from the Devin console, or run `devin` and finish first-run sign-in.
6. Check `devin --version`; run it inside a git repo.

Cloud-only route (no CLI): `app.devin.ai` + GitHub app.

## Termux quirks & workarounds
- A raw `ld.so --library-path` call fails on the 2026 glibc package (`libc.so: invalid ELF header` — that file is a text linker script). **grun is the fix.**
- `DEVIN_API_KEY` is sent as a Bearer header only to `devin.ai` hosts. Override hosts (`DEVIN_MANIFEST`, `DEVIN_URL`) never receive it.
- Phantom process killer (~32 child processes, device-wide): use `tmux` and disable child-process restrictions in Developer Options.
- ⚠️ PyPI `devin-cli` (revanthpobala) is an unofficial Devin API client, not this CLI.

## Limits
- The manifest is fetched live, so the version floats. The hash comes from the same vendor manifest, not from this repo.
- Device-verified to `--version`; long task loops depend on Cognition's backend.

## Sources
- https://static.devin.ai/cli/current/manifest.json (version + sha256 source)
- https://cli.devin.ai/install.sh · https://docs.devin.ai
- Device verification 2026-10-20 (aarch64 Android phone): manifest flow, `devin --version` → `3000.11.92`
