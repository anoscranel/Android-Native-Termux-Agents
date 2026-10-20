#!/data/data/com.termux/files/usr/bin/bash
# Droid (Factory AI) — Termux glibc-runner install: pinned version + sha256-verified (native-side, NO proot/chroot/VM)
# Idempotent: safe to re-run. Never touches login/config; never exports proxies.
set -Eeuo pipefail

VER="${DROID_VERSION:-0.245.0}"   # hash comes from the per-version sidecar, so overrides stay verified
BASE="https://downloads.factory.ai/factory-cli/releases/${VER}/linux/arm64"
DROID_HOME="$PREFIX/opt/droid"
WRAPPER="$PREFIX/bin/droid"

echo "==> Droid (Factory AI): Termux glibc-runner install, pinned @ ${VER}"

echo '==> Enabling Termux glibc repo + tooling…'
pkg install -y glibc-repo
pkg install -y glibc glibc-runner curl coreutils

command -v grun >/dev/null || { echo "!! grun missing (glibc-runner pkg) after install — aborting"; exit 1; }
[ -e "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" ] || { echo "!! glibc loader missing — aborting"; exit 1; }

if [ -x "$DROID_HOME/droid" ] && [ "${DROID_FORCE:-0}" != "1" ]; then
  echo '==> droid binary already staged, skipping download (DROID_FORCE=1 to refresh)'
else
  echo "==> Downloading droid ${VER} (linux/arm64) + sha256 sidecar…"
  TMPD="$(mktemp -d)"
  trap 'rm -rf "$TMPD"' EXIT
  cd "$TMPD"
  curl -fsSLO "$BASE/droid"
  curl -fsSLO "$BASE/droid.sha256"
  echo '==> Verifying checksum…'
  echo "$(awk '{print $1}' droid.sha256)  droid" | sha256sum --check
  mkdir -p "$DROID_HOME"
  mv droid "$DROID_HOME/droid"
  chmod +x "$DROID_HOME/droid"
fi

echo '==> Writing glibc-runner wrapper…'
cat > "$WRAPPER" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
exec grun "$PREFIX/opt/droid/droid" "$@"
EOF
chmod +x "$WRAPPER"

echo '==> Verifying…'
if ! "$WRAPPER" --version; then
  echo '⚠️  droid staged but failed to run under the glibc loader — see README Limits.'
fi

echo '==> done. Run: cd <git repo> && droid  (browser device-flow auth)'
