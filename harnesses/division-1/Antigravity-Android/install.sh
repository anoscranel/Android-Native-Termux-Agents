#!/data/data/com.termux/files/usr/bin/bash
# Antigravity (agy) on native Termux — glibc runner + faccessat2 blob patch (device-verified 1.1.25).
# Idempotent: safe to re-run.
set -Eeuo pipefail

PREFIX=/data/data/com.termux/files/usr
HOME_DIR=/data/data/com.termux/files/home
REL="https://github.com/mrfandu1/patched-cli-payloads/releases/download/payloads-v2"
BIN_DIR="$HOME_DIR/.local/bin"
WRK="$(mktemp -d "$PREFIX/tmp/agy-install.XXXXXX")"
trap 'rm -rf "$WRK"' EXIT

echo '==> installing Termux packages (incl. glibc runtime)'
pkg install -y patchelf zstd nodejs curl glibc-repo
pkg install -y glibc
[ -e "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" ] || { echo '!! glibc loader missing'; exit 1; }

echo '==> fetching checksummed agy payload (third-party binary — trust decision)'
curl --noproxy '*' -fsSL "$REL/agy.bin.zst" -o "$WRK/agy.bin.zst"
curl --noproxy '*' -fsSL "$REL/SHA256SUMS" -o "$WRK/SHA256SUMS"
( cd "$WRK" && grep 'agy\.bin\.zst' SHA256SUMS | sha256sum -c - )

echo '==> decompressing'
mkdir -p "$BIN_DIR"
zstd -d -f "$WRK/agy.bin.zst" -o "$BIN_DIR/agy.bin"
chmod +x "$BIN_DIR/agy.bin"

echo '==> patchelf: rpath -> Termux glibc'
patchelf --set-rpath "$PREFIX/glibc/lib" "$BIN_DIR/agy.bin"
patchelf --print-rpath "$BIN_DIR/agy.bin" | grep -q 'glibc/lib' \
  || { echo '!! rpath patch did not stick'; exit 1; }

echo '==> patching faccessat2 (syscall 439) -> faccessat (48)'
cp "$BIN_DIR/agy.bin" "$BIN_DIR/agy.bin.bak"
node <<'EOF'
// Reference: mrfandu1/patched-cli-payloads scripts/patch-agy-faccessat2.js
const fs = require('fs');
const path = process.env.HOME + '/.local/bin/agy.bin';
const OLD = Buffer.from([0xe0, 0x36, 0x80, 0xd2]); // movz x0,#439
const NEW = Buffer.from([0x00, 0x06, 0x80, 0xd2]); // movz x0,#48
const buf = fs.readFileSync(path);
let sites = 0;
for (let off = 0; off + 4 <= buf.length; off += 4) {
  if (buf[off] === OLD[0] && buf[off+1] === OLD[1] &&
      buf[off+2] === OLD[2] && buf[off+3] === OLD[3]) {
    NEW.copy(buf, off); sites++;
  }
}
if (sites === 0) {
  console.error('!! zero patch sites — unexpected agy build, aborting');
  process.exit(1);
}
fs.writeFileSync(path, buf);
console.log(`==> patched ${sites} faccessat2 call site(s)`);
EOF
rm -f "$BIN_DIR/agy.bin.bak"

echo '==> writing wrapper ~/.local/bin/agy (LD_PRELOAD cleared, proxy wrapper-scoped)'
cat > "$BIN_DIR/agy" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
export HTTP_PROXY=http://127.0.0.1:18080
export HTTPS_PROXY=http://127.0.0.1:18080
export NO_PROXY=localhost,127.0.0.1
export SSL_CERT_FILE="${SSL_CERT_FILE:-/data/data/com.termux/files/usr/etc/tls/cert.pem}"
[ -x "$HOME/bin/ensure-local-proxy.sh" ] && "$HOME/bin/ensure-local-proxy.sh" >/dev/null 2>&1
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
