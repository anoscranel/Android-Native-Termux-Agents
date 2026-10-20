#!/data/data/com.termux/files/usr/bin/bash
# MiniMax Code (@minimax-ai/code, bin `mcode`) — native Termux install + ripgrep shim
# Idempotent: safe to re-run. Never touches login/config; never exports proxies.
set -Eeuo pipefail

PKG_NAME="@minimax-ai/code"
PKG_VER="${MCODE_VERSION:-0.6.12}"
RG_DIR="$PREFIX/lib/node_modules/@minimax-ai/code/node_modules/@vscode/ripgrep/bin"
RG_TARGET="$RG_DIR/rg"

echo '==> MiniMax Code: native Termux install (npm route + ripgrep shim)'

echo '==> Ensuring nodejs, Termux ripgrep + build tools…'
pkg install -y nodejs ripgrep build-essential python

install_pkg() {
  npm install -g "${PKG_NAME}@${PKG_VER}" --force
}

if npm ls -g --depth=0 2>/dev/null | grep -q "minimax-ai/code@${PKG_VER}"; then
  echo "==> ${PKG_NAME}@${PKG_VER} already installed, skipping npm install"
else
  echo "==> Installing ${PKG_NAME}@${PKG_VER} (npm global)…"
  if ! install_pkg; then
    echo '==> npm install exited nonzero (likely @vscode/ripgrep postinstall tried to run its glibc rg) — pre-staging Termux rg and retrying…'
    mkdir -p "$RG_DIR"
    cp "$PREFIX/bin/rg" "$RG_TARGET"
    install_pkg
  fi
fi

echo '==> Applying ripgrep shim (replace glibc rg with Termux rg)…'
mkdir -p "$RG_DIR"
cp "$PREFIX/bin/rg" "$RG_TARGET"

echo '==> Verifying…'
mcode --version

echo '==> done. Run: mcode  (log in with a subscription key from platform.minimax.io/console/plan)'
