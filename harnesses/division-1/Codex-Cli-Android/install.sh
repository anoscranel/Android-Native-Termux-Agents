#!/data/data/com.termux/files/usr/bin/bash
# Codex CLI on native Termux — static-musl vendor binary + Node wrapper (device-verified 0.154.0).
# Idempotent: safe to re-run. Never touches ~/.codex login state.
set -Eeuo pipefail

PREFIX=/data/data/com.termux/files/usr

# Pinned versions (per division-1 findings 2026-10-20)
CODEX_VER=0.162.0-alpha.10
REL="https://github.com/mrfandu1/patched-cli-payloads/releases/download/payloads-v2"

VENDOR="$PREFIX/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-arm64"
VENDOR_BIN="$VENDOR/vendor/aarch64-unknown-linux-musl/bin"
WRK="$(mktemp -d "$PREFIX/tmp/codex-install.XXXXXX")"
trap 'rm -rf "$WRK"' EXIT

echo '==> installing Termux packages'
pkg install -y nodejs curl zstd

echo "==> installing @openai/codex@$CODEX_VER (JS launcher)"
npm install -g "@openai/codex@$CODEX_VER"

echo '==> fetching checksummed static-musl vendor binaries (third-party payload — trust decision)'
curl --noproxy '*' -fsSL "$REL/codex.bin.zst" -o "$WRK/codex.bin.zst"
curl --noproxy '*' -fsSL "$REL/codex-code-mode-host.bin.zst" -o "$WRK/codex-code-mode-host.bin.zst"
curl --noproxy '*' -fsSL "$REL/SHA256SUMS" -o "$WRK/SHA256SUMS"
( cd "$WRK" && grep -E '(codex\.bin\.zst|codex-code-mode-host\.bin\.zst)' SHA256SUMS | sha256sum -c - )

echo '==> placing vendor binaries'
mkdir -p "$VENDOR_BIN"
zstd -d -f "$WRK/codex.bin.zst" -o "$VENDOR_BIN/codex"
zstd -d -f "$WRK/codex-code-mode-host.bin.zst" -o "$VENDOR_BIN/codex-code-mode-host"
chmod +x "$VENDOR_BIN/codex" "$VENDOR_BIN/codex-code-mode-host"

if [ ! -f "$VENDOR/package.json" ]; then
  printf '{"name":"@openai/codex-linux-arm64","version":"%s-linux-arm64"}\n' "$CODEX_VER" > "$VENDOR/package.json"
fi

echo '==> verifying vendor binaries are statically linked'
if command -v patchelf >/dev/null 2>&1; then
  patchelf --print-interpreter "$VENDOR_BIN/codex" 2>&1 | grep -qi 'statically linked' \
    || echo '!! warning: codex binary not reported statically linked'
fi

echo '==> writing Node wrapper at $PREFIX/bin/codex (proxy wrapper-scoped)'
cat > "$PREFIX/bin/codex" <<'EOF'
#!/data/data/com.termux/files/usr/bin/node
process.env.HTTP_PROXY = 'http://127.0.0.1:18080';
process.env.HTTPS_PROXY = 'http://127.0.0.1:18080';
process.env.NO_PROXY = 'localhost,127.0.0.1';
process.env.SSL_CERT_FILE = process.env.SSL_CERT_FILE || '/data/data/com.termux/files/usr/etc/tls/cert.pem';
import('/data/data/com.termux/files/usr/lib/node_modules/@openai/codex/bin/codex.js')
EOF
chmod +x "$PREFIX/bin/codex"

if [ ! -x "$HOME/bin/ensure-local-proxy.sh" ]; then
  echo '!! note: loopback proxy supervisor (~/bin/ensure-local-proxy.sh) not found.'
  echo '!! the wrapper points at 127.0.0.1:18080 — install the supervisor from'
  echo '!! https://github.com/mrfandu1/patched-cli-payloads (proxy/ dir), or remove'
  echo '!! the HTTP_PROXY/HTTPS_PROXY lines from $PREFIX/bin/codex.'
fi

echo '==> done. Run: codex login --device-auth  (then: codex)'
