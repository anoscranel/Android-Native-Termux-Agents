#!/data/data/com.termux/files/usr/bin/bash
# perchai-cli (Perch AI) installer for native Android Termux — no proot/chroot/VM.
# @napi-rs/canvas resolves its android-arm64 prebuild today (checked on a real
# phone, 2026-10-20). The script still pins the version and keeps two fallbacks
# in case a future canvas release breaks the plain install.
set -Eeuo pipefail

PKG="perchai-cli"
VERSION="${PERCHAI_VERSION:-2.4.112}"   # pinned default: registry-verified 2026-10-20

echo '==>' "perchai-cli (Perch AI) installer (native Termux)"

command -v node >/dev/null || { echo '==>' "Installing nodejs"; pkg install -y nodejs; }

node_major="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$node_major" -lt 18 ]; then
  echo "!! perchai-cli needs Node 18+; found $(node --version)" >&2
  exit 1
fi

echo '==>' "Installing ${PKG}@${VERSION} (idempotent: safe to re-run)"
if npm install -g "${PKG}@${VERSION}"; then
  echo '==>' "Plain install succeeded"
elif { echo '⚠️  Plain install failed (likely @napi-rs/canvas prebuild)'
       echo '==>' "Retrying with --omit=optional"; npm install -g --omit=optional "${PKG}@${VERSION}"; }; then
  echo '==>' "Installed with --omit=optional"
else
  echo '==>' "Retrying with --ignore-scripts (last resort)"
  npm install -g --ignore-scripts "${PKG}@${VERSION}"
fi

echo '==>' "Verifying"
if ! command -v perch >/dev/null; then
  echo "!! perch binary not on PATH after install" >&2
  exit 1
fi
perch --version 2>/dev/null || echo '⚠️  perch installs but --version failed; canvas may be breaking startup — report this'

echo '==>' "done. Run: perch login"
