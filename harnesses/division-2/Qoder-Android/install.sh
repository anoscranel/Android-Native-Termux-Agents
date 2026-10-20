#!/data/data/com.termux/files/usr/bin/bash
# Qoder CLI (@qoder-ai/qodercli) — native Termux install (npm route, no proot)
# Idempotent: safe to re-run. Never touches login/config; never exports proxies.
set -Eeuo pipefail

PKG_NAME="@qoder-ai/qodercli"
PKG_VER="${QODER_VERSION:-1.1.74}"

echo '==> Qoder CLI: native Termux install (npm route)'

echo '==> Ensuring nodejs via pkg…'
if ! command -v node >/dev/null 2>&1; then
  pkg install -y nodejs
else
  echo '==> nodejs already present, skipping'
fi

if npm ls -g --depth=0 2>/dev/null | grep -q "qodercli@${PKG_VER}"; then
  echo "==> ${PKG_NAME}@${PKG_VER} already installed, skipping npm install"
else
  echo "==> Installing ${PKG_NAME}@${PKG_VER} (npm global)…"
  npm install -g "${PKG_NAME}@${PKG_VER}" --force
fi

echo '==> Verifying…'
if ! qodercli --version; then
  echo '⚠️  qodercli present but failed to start — native-dep risk (sharp OK on Termux, @silvia-odwyer/photon-node has no android-arm64 prebuild). See README Termux quirks.'
fi

echo '==> done. Run: qodercli  (then /login)'
