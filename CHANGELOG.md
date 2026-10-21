# Changelog

## v1.0.0 — 2026-10-21

Initial release: 18 harness guides and 13 install scripts for native Termux on aarch64 Android. This release includes the fixes from an independent audit:

- **Codex:** the installer no longer overwrites upstream `codex.js` through the npm symlink (a fresh install used to start a wrapper that imported itself).
- **All scripts:** every wrapper write removes the old file or symlink first, so vendor files are never overwritten through a link.
- **Codex / Antigravity:** the loopback proxy is set only if its supervisor (`~/bin/ensure-local-proxy.sh`) is installed.
- **Supply chain:** Alpine APK hashes and the Claude Code, Codex and Antigravity payload hashes are hard-coded and fail closed; payload hashes are trust-on-first-use from the release `SHA256SUMS`.
- **Devin:** `DEVIN_URL` requires `DEVIN_SHA256`; `DEVIN_API_KEY` is sent only to `devin.ai` hosts.
- **Upgrades:** Claude Code and Droid now detect version changes with a `.version` stamp.
- **Hardening:** Cursor replaces `~/.local/bin/agent` only if it is Cursor's own link; DeepSeek Harness pins node-gyp and picks the newest pnpm copy; Opencode installs its `.deb` with `apt` so dependencies resolve.
- **Docs:** verification claims now match what ran on the phone; Hermes leads with the verified git + venv route; phantom-process-killer advice corrected; all READMEs follow one skeleton.
- **Repo:** added `SECURITY.md`, this changelog, and a shellcheck workflow.
