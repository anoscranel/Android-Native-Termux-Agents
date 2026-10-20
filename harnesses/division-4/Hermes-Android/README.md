# Hermes on Termux (native Android, no proot)

**Verdict:** NATIVE · **Confidence:** high — device-verified 2026-10-20 (install, CLI smoke, and a full agent turn against an OpenAI-compatible endpoint)

## TL;DR

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

## What it is

Hermes Agent is NousResearch's open-source agent CLI. It is a pure-Python package (`hermes_cli`, entry point `hermes_cli.main:main`), so it installs and runs directly on Termux's native Python — no proot, no chroot, no glibc/musl shims. Upstream repo: `https://github.com/NousResearch/Hermes-Agent`. Verified working on-device (v0.21.5, 2026-10-20) as a git clone + Python venv symlinked into `$PREFIX/bin/hermes`.

## One-command install

The official installer is the TL;DR command above (from the upstream README). It creates `~/.hermes/hermes-agent` with a managed venv — that is the whole install, so this harness ships no local `install.sh`.

## Step-by-step

If you prefer the manual route (this is the autopsied on-device layout):

```bash
git clone https://github.com/NousResearch/Hermes-Agent.git ~/.hermes/hermes-agent
python -m venv ~/.hermes/hermes-agent/venv
~/.hermes/hermes-agent/venv/bin/pip install -e "$HOME/.hermes/hermes-agent[all]"
ln -sf ~/.hermes/hermes-agent/venv/bin/hermes $PREFIX/bin/hermes
```

Termux ships a native Python 3.13, which is all Hermes needs. Upstream's dev path uses `uv`; plain `venv`+`pip` works the same.

## Termux quirks & workarounds

- Pure Python → no phantom-killer problem (that class only hits musl/glibc-shipped binaries; see the Opencode harness).
- TMPDIR: Python respects `$PREFIX/tmp` out of the box; nothing to override.
- Auth is API-key driven (provider keys under `~/.hermes`) — phone-friendly, no desktop-browser loop for basic use.
- Keep the venv self-contained. Do not symlink system site-packages into it — Termux Python upgrades can silently break `.pyc` layouts otherwise.
- Auth/login state and `~/.hermes` config are yours; the installer and this README never touch them.

## Limits

- Needs network access for model APIs (it is an agent harness, not a local model).
- Upstream moves fast; pin your clone if you need reproducibility.

## Sources

- https://github.com/NousResearch/Hermes-Agent
- https://hermes-agent.nousresearch.com/install.sh (official one-liner, from the repo README)
