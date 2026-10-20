# Devin on Termux (native Android, no proot)
**Verdict:** PATCHED-NATIVE · **Confidence:** high — device-verified 2026-10-20 (`devin 3000.11.92` ran natively)

## TL;DR
```bash
curl -fsSL https://raw.githubusercontent.com/anoscranel/Android-Native-Termux-Agents/master/harnesses/division-3/Devin-Android/install.sh | bash
```

## What it is
Cognition's local CLI **Devin for Terminal** (`devin`) — local command-line coding agent, separate from cloud Devin-in-a-VM, with `/handoff` for terminal→cloud offloading. Local tools: Bash/Read/Write/Edit/Glob/Grep/WebFetch/WebSearch. Ships as a glibc aarch64 tarball → runs via Termux's own **grun** glibc runner.

## Step-by-step (as the oneliner does it)
1. `pkg install glibc-repo && pkg install glibc glibc-runner curl tar python` — grun handles the loader + library path + preload-sanitize.
2. The installer reads the vendor manifest `https://static.devin.ai/cli/current/manifest.json` → version + URL + **published sha256**, downloads the tarball to `$TMPDIR`, verifies the hash, extracts to `$PREFIX/opt/devin` (`bin/devin` + `share/`).
3. Wrapper `$PREFIX/bin/devin`: `exec grun $PREFIX/opt/devin/bin/devin "$@"`.
4. Auth: `DEVIN_API_KEY=...` from the Devin console, or launch `devin` and complete first-run sign-in.
5. Verify `devin --version`; run inside a git repo.

Cloud-only route (no CLI): `app.devin.ai` + GitHub app.

## Termux quirks & workarounds
- Raw `ld.so --library-path` fails on the 2026 glibc SDK (`libc.so: invalid ELF header` — the SDK's libc is an ASCII ld-script). **grun is the fix.**
- Heavier runtime — keep sessions under `tmux` + `termux-wake-lock`; some Android OEMs terminate background processes aggressively.
- ⚠️ Don't install PyPI `devin-cli` (revanthpobala) believing it's official — it's an unofficial Devin API client.

## Limits
- Manifest is live-fetched at install time (version floats); the `DEVIN_URL=` override pins an older tarball explicitly. Hash is vendor-published, not mirrored.
- Device-verified to `--version`; long task loops still depend on Cognition's backend.

## Sources
- https://static.devin.ai/cli/current/manifest.json (version + sha256 source)
- https://cli.devin.ai/install.sh · https://docs.devin.ai
- Device verification 2026-10-20 (this author's aarch64 Android phone): manifest-tested flow, `devin --version` → `3000.11.92`
