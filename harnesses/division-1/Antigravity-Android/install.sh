#!/data/data/com.termux/files/usr/bin/bash
# Antigravity (agy) on native Termux — glibc loader + faccessat2 blob patch.
# The method runs on a real aarch64 Android phone (agy 1.1.25 installed the same
# way); this script pins a different payload and was not re-run there.
# Idempotent: safe to re-run.
set -Eeuo pipefail

PREFIX=/data/data/com.termux/files/usr
HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
REL="https://github.com/mrfandu1/patched-cli-payloads/releases/download/payloads-v2"
# hash pinned from the release SHA256SUMS on 2026-10-21 (trust-on-first-use)
AGY_SHA256=4e32b762d11328f48171c0b0060f9d9b3e37cf1eceb36e5d3d95d8ac197a4677
BIN_DIR="$HOME_DIR/.local/bin"
WRK="$(mktemp -d "$PREFIX/tmp/agy-install.XXXXXX")"
trap 'rm -rf "$WRK"' EXIT

echo '==> installing Termux packages (incl. glibc runtime)'
pkg install -y patchelf zstd nodejs curl glibc-repo
pkg install -y glibc
[ -e "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" ] || { echo '!! glibc loader missing'; exit 1; }

echo '==> fetching pinned agy payload (third-party binary — trust decision)'
curl --noproxy '*' -fsSL "$REL/agy.bin.zst" -o "$WRK/agy.bin.zst"
echo "$AGY_SHA256  $WRK/agy.bin.zst" | sha256sum -c - \
  || { echo '!! sha256 mismatch for agy.bin.zst — refusing to install'; exit 1; }

echo '==> decompressing'
mkdir -p "$BIN_DIR"
rm -f "$BIN_DIR/agy.bin"
zstd -d -f "$WRK/agy.bin.zst" -o "$BIN_DIR/agy.bin"
chmod +x "$BIN_DIR/agy.bin"

echo '==> patchelf: rpath -> Termux glibc'
patchelf --set-rpath "$PREFIX/glibc/lib" "$BIN_DIR/agy.bin"
patchelf --print-rpath "$BIN_DIR/agy.bin" | grep -q 'glibc/lib' \
  || { echo '!! rpath patch did not stick'; exit 1; }

echo '==> patching faccessat2 (syscall 439) -> faccessat (48)'
# The upstream reference publishes no expected site count for this build, so the
# patch prints the count and requires it to be nonzero. Set AGY_EXPECTED_SITES
# to make an exact count mandatory.
AGY_EXPECTED_SITES="${AGY_EXPECTED_SITES:-}" node <<'EOF'
// Reference: mrfandu1/patched-cli-payloads scripts/patch-agy-faccessat2.js
const fs = require('fs');
const path = process.env.HOME + '/.local/bin/agy.bin';
const OLD = Buffer.from([0xe0, 0x36, 0x80, 0xd2]); // movz x0,#439
const NEW = Buffer.from([0x00, 0x06, 0x80, 0xd2]); // movz x0,#48
const buf = fs.readFileSync(path);
const sites = [];
for (let off = 0; off + 4 <= buf.length; off += 4) {
  if (buf[off] === OLD[0] && buf[off+1] === OLD[1] &&
      buf[off+2] === OLD[2] && buf[off+3] === OLD[3]) {
    sites.push(off);
  }
}
console.log(`==> found ${sites.length} faccessat2 call site(s)`);
if (sites.length === 0) {
  console.error('!! zero patch sites — unexpected agy build, aborting');
  process.exit(1);
}
const want = process.env.AGY_EXPECTED_SITES;
if (want && Number(want) !== sites.length) {
  console.error(`!! expected ${want} site(s), found ${sites.length} — unexpected agy build, aborting`);
  process.exit(1);
}
for (const off of sites) NEW.copy(buf, off);
fs.writeFileSync(path, buf);
console.log(`==> patched ${sites.length} faccessat2 call site(s)`);
EOF

echo '==> writing wrapper ~/.local/bin/agy (LD_PRELOAD cleared)'
rm -f "$BIN_DIR/agy"
cat > "$BIN_DIR/agy" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# The loopback proxy is used only when its supervisor is installed.
if [ -x "$HOME/bin/ensure-local-proxy.sh" ]; then
  "$HOME/bin/ensure-local-proxy.sh" >/dev/null 2>&1 || true
  export HTTP_PROXY=http://127.0.0.1:18080
  export HTTPS_PROXY=http://127.0.0.1:18080
  export NO_PROXY=localhost,127.0.0.1
fi
export SSL_CERT_FILE="${SSL_CERT_FILE:-/data/data/com.termux/files/usr/etc/tls/cert.pem}"
exec env -u LD_PRELOAD /data/data/com.termux/files/usr/glibc/lib/ld-linux-aarch64.so.1 \
  --library-path /data/data/com.termux/files/usr/glibc/lib \
  "$HOME/.local/bin/agy.bin" "$@"
EOF
chmod +x "$BIN_DIR/agy"

case ":$PATH:" in
  *":$BIN_DIR:"*) : ;;
  *) echo "!! $BIN_DIR not in PATH — add it in your shell rc" ;;
esac

echo '==> done. Run: agy'
