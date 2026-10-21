# Hermes on Termux (native Android, no proot)
**Verdict:** NATIVE · **Confidence:** high — device-verified 2026-10-20 (v0.21.5 via git + venv: install, CLI smoke test, and a full agent turn against an OpenAI-compatible endpoint)

## TL;DR
```bash
pkg install -y git python && git clone https://github.com/NousResearch/Hermes-Agent.git ~/.hermes/hermes-agent && python -m venv ~/.hermes/hermes-agent/venv && ~/.hermes/hermes-agent/venv/bin/pip install -e "$HOME/.hermes/hermes-agent[all]" && ln -sf ~/.hermes/hermes-agent/venv/bin/hermes "$PREFIX/bin/hermes"
```

## What it is
Hermes Agent is NousResearch's open-source agent CLI. It is a pure-Python package (`hermes_cli`, entry point `hermes_cli.main:main`), so it runs directly on Termux's native Python — no glibc or musl shims. Upstream repo: `https://github.com/NousResearch/Hermes-Agent`.

## One-command install
The TL;DR line is the route verified on a real aarch64 Android phone: a git clone plus a Python venv, linked into `$PREFIX/bin/hermes`. Re-running it fails at `git clone` once the folder exists; to upgrade, run `git -C ~/.hermes/hermes-agent pull` and repeat the `pip install` step.

Alternative — the official installer, ⚠️ not verified on Termux:
```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

## Step-by-step
```bash
pkg install -y git python
git clone https://github.com/NousResearch/Hermes-Agent.git ~/.hermes/hermes-agent
python -m venv ~/.hermes/hermes-agent/venv
~/.hermes/hermes-agent/venv/bin/pip install -e "$HOME/.hermes/hermes-agent[all]"
ln -sf ~/.hermes/hermes-agent/venv/bin/hermes "$PREFIX/bin/hermes"
hermes --version
```

Termux's native Python 3.13 is all Hermes needs. Upstream's dev path uses `uv`; plain `venv` + `pip` works the same.

## Termux quirks & workarounds
- Phantom process killer: Android caps child processes at ~32 device-wide, whatever libc they use — Python tools and shell commands count too. Run long sessions in `tmux` and disable child-process restrictions in Developer Options.
- TMPDIR: Python respects `$PREFIX/tmp` out of the box.
- Auth is API-key driven (provider keys under `~/.hermes`) — phone-friendly, no browser login needed for basic use.
- Keep the venv self-contained. Do not link system site-packages into it — a Termux Python upgrade can break it.

## Limits
- Needs network access for model APIs (it is an agent harness, not a local model).
- Upstream moves fast; check out a tag in the clone if you need reproducibility.
- This harness ships no `install.sh`; the commands above are the whole install.

## Sources
- https://github.com/NousResearch/Hermes-Agent
- https://hermes-agent.nousresearch.com/install.sh (official installer, from the repo README; ⚠️ not verified on Termux)
