#!/data/data/com.termux/files/usr/bin/bash
# Kimi Code CLI (@moonshot-ai/kimi-code) — native Termux install (npm + node-pty source build)
# Idempotent: safe to re-run. Never touches login/config; never exports proxies.
set -Eeuo pipefail

PKG_NAME="@moonshot-ai/kimi-code"
PKG_VER="${KIMI_VERSION:-2.2.0}"

echo '==> Kimi Code CLI: native Termux install (npm route)'

echo '==> Ensuring nodejs + native build tools (node-pty compiles from source via node-gyp)…'
pkg install -y nodejs make clang python

if npm ls -g --depth=0 2>/dev/null | grep -q "kimi-code@${PKG_VER}"; then
  echo "==> ${PKG_NAME}@${PKG_VER} already installed, skipping npm install"
else
  echo "==> Installing ${PKG_NAME}@${PKG_VER} (npm global; node-pty build takes a moment)…"
  if ! npm install -g "${PKG_NAME}@${PKG_VER}"; then
    echo '==> node-gyp/node-pty build failed — widening toolchain and retrying once…'
    pkg install -y build-essential lld
    npm install -g "${PKG_NAME}@${PKG_VER}"
  fi
fi

echo '==> Verifying…'
kimi --version

echo '⚠️  Fallback if the npm route keeps failing: the vendor script downloads a glibc binary that runs under the Termux glibc runner (glibc-repo + ld.so --library-path) — see README.'

echo '==> done. Run: cd <project> && kimi  (then /login)'
