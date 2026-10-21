#!/data/data/com.termux/files/usr/bin/bash
# Codex CLI on native Termux — static-musl vendor binary + Node wrapper.
# The method runs on a real aarch64 Android phone (codex-cli 0.154.0 installed
# the same way); this script pins a different payload and was not re-run there.
# Idempotent: safe to re-run. Never touches ~/.codex login state.
set -Eeuo pipefail

PREFIX=/data/data/com.termux/files/usr

# Pinned versions (2026-10-20)
CODEX_VER=0.162.0-alpha.10
REL="https://github.com/mrfandu1/patched-cli-payloads/releases/download/payloads-v2"
# hash pinned from the release SHA256SUMS on 2026-10-21 (trust-on-first-use)
CODEX_SHA256=642373e1151e2495a9be1cb170beff963fd0a24683db0c0205360042c4ed8802
CODEX_HOST_SHA256=9f3be1e7c74be4304e533566482f8d240a34ae3e29d5c176b6cb28775c73a9bf

VENDOR="$PREFIX/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-arm64"
VENDOR_BIN="$VENDOR/vendor/aarch64-unknown-linux-musl/bin"
WRK="$(mktemp -d "$PREFIX/tmp/codex-install.XXXXXX")"
trap 'rm -rf "$WRK"' EXIT

echo '==> installing Termux packages'
pkg install -y nodejs curl zstd

echo "==> installing @openai/codex@$CODEX_VER (JS launcher)"
# A wrapper from an earlier run is a regular file; npm would refuse to replace it.
rm -f "$PREFIX/bin/codex"
npm install -g "@openai/codex@$CODEX_VER"

echo '==> fetching pinned static-musl vendor binaries (third-party payload — trust decision)'
curl --noproxy '*' -fsSL "$REL/codex.bin.zst" -o "$WRK/codex.bin.zst"
curl --noproxy '*' -fsSL "$REL/codex-code-mode-host.bin.zst" -o "$WRK/codex-code-mode-host.bin.zst"
echo "$CODEX_SHA256  $WRK/codex.bin.zst" | sha256sum -c - \
  || { echo '!! sha256 mismatch for codex.bin.zst — refusing to install'; exit 1; }
echo "$CODEX_HOST_SHA256  $WRK/codex-code-mode-host.bin.zst" | sha256sum -c - \
  || { echo '!! sha256 mismatch for codex-code-mode-host.bin.zst — refusing to install'; exit 1; }

echo '==> placing vendor binaries'
mkdir -p "$VENDOR_BIN"
rm -f "$VENDOR_BIN/codex" "$VENDOR_BIN/codex-code-mode-host"
zstd -d -f "$WRK/codex.bin.zst" -o "$VENDOR_BIN/codex"
zstd -d -f "$WRK/codex-code-mode-host.bin.zst" -o "$VENDOR_BIN/codex-code-mode-host"
chmod +x "$VENDOR_BIN/codex" "$VENDOR_BIN/codex-code-mode-host"

if [ ! -f "$VENDOR/package.json" ]; then
  printf '{"name":"@openai/codex-linux-arm64","version":"%s-linux-arm64"}\n' "$CODEX_VER" > "$VENDOR/package.json"
fi

echo '==> verifying vendor binaries are statically linked'
if command -v patchelf >/dev/null 2>&1; then
  # patchelf exits non-zero on a static binary; capture its message instead.
  pe_out="$(patchelf --print-interpreter "$VENDOR_BIN/codex" 2>&1 || true)"
  grep -qi 'statically linked' <<<"$pe_out" \
    || echo '!! warning: codex binary not reported statically linked'
fi

echo '==> writing Node wrapper at $PREFIX/bin/codex'
# npm made $PREFIX/bin/codex a symlink to upstream bin/codex.js; remove it so the
# wrapper does not overwrite codex.js through the link.
rm -f "$PREFIX/bin/codex"
cat > "$PREFIX/bin/codex" <<'EOF'
#!/data/data/com.termux/files/usr/bin/node
// The loopback proxy is used only when its supervisor is installed.
const fs = require('fs');
const sup = (process.env.HOME || '/data/data/com.termux/files/home') + '/bin/ensure-local-proxy.sh';
let hasSupervisor = false;
try { fs.accessSync(sup, fs.constants.X_OK); hasSupervisor = true; } catch (e) { hasSupervisor = false; }
if (hasSupervisor) {
  require('child_process').spawnSync(sup, [], { stdio: 'ignore' });
  process.env.HTTP_PROXY = 'http://127.0.0.1:18080';
  process.env.HTTPS_PROXY = 'http://127.0.0.1:18080';
  process.env.NO_PROXY = 'localhost,127.0.0.1';
}
process.env.SSL_CERT_FILE = process.env.SSL_CERT_FILE || '/data/data/com.termux/files/usr/etc/tls/cert.pem';
import('/data/data/com.termux/files/usr/lib/node_modules/@openai/codex/bin/codex.js');
EOF
chmod +x "$PREFIX/bin/codex"

echo '==> done. Run: codex login --device-auth  (then: codex)'
