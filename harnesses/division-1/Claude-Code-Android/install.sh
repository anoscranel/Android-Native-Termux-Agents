#!/data/data/com.termux/files/usr/bin/bash
# Claude Code on native Termux — musl patchelf route (device-verified 2.1.295).
# Idempotent: safe to re-run. Never touches ~/.claude login state.
set -Eeuo pipefail

PREFIX=/data/data/com.termux/files/usr
HOME_DIR=/data/data/com.termux/files/home

# Pinned versions (per division-1 findings 2026-10-20)
CLAUDE_NPM_VER=2.1.288
ALPINE_VER=v3.24
MUSL_PKGS="musl-1.2.6-r2 libgcc-15.2.0-r5 libstdc++-15.2.0-r5"
ALPINE_BASE="https://dl-cdn.alpinelinux.org/alpine/${ALPINE_VER}/main/aarch64"
REL="https://github.com/mrfandu1/patched-cli-payloads/releases/download/payloads-v2"

MUSL_HOME="$HOME_DIR/.local"          # loader lands at $MUSL_HOME/lib/ld-musl-aarch64.so.1
MUSL_PREFIX="$PREFIX/lib/musl"        # alternate rpath entries (mrfandu1 layout)
BIN_DIR="$HOME_DIR/.local/bin"
WRK="$(mktemp -d "$PREFIX/tmp/claude-install.XXXXXX")"
trap 'rm -rf "$WRK"' EXIT

echo '==> installing Termux packages'
pkg install -y nodejs zstd patchelf tar curl

echo "==> fetching Alpine ${ALPINE_VER} musl runtime (pinned: ${MUSL_PKGS})"
mkdir -p "$MUSL_HOME" "$MUSL_PREFIX"
for pkgname in $MUSL_PKGS; do
  apk="$WRK/$pkgname.apk"
  curl --noproxy '*' -fsSL "$ALPINE_BASE/$pkgname.apk" -o "$apk"
  # gzip integrity check (findings publish no APK sha256 — hash printed for manual verify)
  tar -tzf "$apk" >/dev/null
  sha256sum "$apk"
  tar -xzf "$apk" -C "$MUSL_HOME"
  tar -xzf "$apk" -C "$MUSL_PREFIX"
done
[ -e "$MUSL_HOME/lib/ld-musl-aarch64.so.1" ] || { echo '!! musl loader missing after extract'; exit 1; }

echo "==> installing @anthropic-ai/claude-code@$CLAUDE_NPM_VER (npm package + JS shim)"
npm install -g "@anthropic-ai/claude-code@$CLAUDE_NPM_VER"

echo '==> fetching checksummed musl-native claude binary (third-party payload — trust decision)'
curl --noproxy '*' -fsSL "$REL/claude.bin.zst" -o "$WRK/claude.bin.zst"
curl --noproxy '*' -fsSL "$REL/SHA256SUMS" -o "$WRK/SHA256SUMS"
( cd "$WRK" && grep 'claude\.bin\.zst' SHA256SUMS | sha256sum -c - )

mkdir -p "$BIN_DIR"
echo '==> decompressing + patching binary'
if [ ! -x "$BIN_DIR/claude-bin" ] || [ "${FORCE:-0}" = "1" ]; then
  zstd -d -f "$WRK/claude.bin.zst" -o "$BIN_DIR/claude-bin"
  chmod +x "$BIN_DIR/claude-bin"
fi
patchelf --set-interpreter "$MUSL_HOME/lib/ld-musl-aarch64.so.1" \
  --set-rpath "$MUSL_HOME/lib:$MUSL_PREFIX/lib:$MUSL_PREFIX/usr/lib" \
  "$BIN_DIR/claude-bin"
patchelf --print-interpreter "$BIN_DIR/claude-bin" | grep -q 'ld-musl-aarch64' \
  || { echo '!! interpreter patch did not stick'; exit 1; }

echo '==> writing wrapper ~/.local/bin/claude (DISABLE_AUTOUPDATER=1, LD_PRELOAD cleared)'
cat > "$BIN_DIR/claude" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
export DISABLE_AUTOUPDATER=1
exec env LD_PRELOAD= /data/data/com.termux/files/home/.local/bin/claude-bin "$@"
EOF
chmod +x "$BIN_DIR/claude"

case ":$PATH:" in
  *":$BIN_DIR:"*) : ;;
  *) echo "!! $BIN_DIR not in PATH — add it (before \$PREFIX/bin) in your shell rc" ;;
esac

echo '==> done. Run: claude'
