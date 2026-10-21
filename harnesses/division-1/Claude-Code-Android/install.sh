#!/data/data/com.termux/files/usr/bin/bash
# Claude Code on native Termux — musl patchelf route.
# The method runs on a real aarch64 Android phone (claude 2.1.295 installed the
# same way); this script pins a different payload and was not re-run there.
# Idempotent: safe to re-run. Never touches ~/.claude login state.
set -Eeuo pipefail

PREFIX=/data/data/com.termux/files/usr
HOME_DIR="${HOME:-/data/data/com.termux/files/home}"

# Pinned versions (2026-10-20)
CLAUDE_NPM_VER=2.1.288
ALPINE_VER=v3.24
ALPINE_BASE="https://dl-cdn.alpinelinux.org/alpine/${ALPINE_VER}/main/aarch64"
REL="https://github.com/mrfandu1/patched-cli-payloads/releases/download/payloads-v2"
# Alpine APK hashes: match the upstream reference installer and a fresh download (2026-10-21).
declare -A MUSL_APKS=(
  [musl-1.2.6-r2]=5e9674b7f41152fe2119093b5cb4c13eaaadb19c2d5422b2d7267913e663ee6e
  [libgcc-15.2.0-r5]=369aaa6e9d099a737bad6dd3e6c2fe7bb1547ca26d22b94ee0411228f709b403
  [libstdc++-15.2.0-r5]=2302e766d4e4926038ec166ecb85837ee884576115236ddb565e3a5fca4a11d7
)
# hash pinned from the release SHA256SUMS on 2026-10-21 (trust-on-first-use)
CLAUDE_SHA256=623a14eee518edd2770f6f20a51d76e37e08b6a3ec917a49e177c4aa51b745c8

MUSL_HOME="$HOME_DIR/.local"          # loader lands at $MUSL_HOME/lib/ld-musl-aarch64.so.1
MUSL_PREFIX="$PREFIX/lib/musl"        # alternate rpath entries (payload pack layout)
BIN_DIR="$HOME_DIR/.local/bin"
VERSION_FILE="$BIN_DIR/.claude-bin.version"
WRK="$(mktemp -d "$PREFIX/tmp/claude-install.XXXXXX")"
trap 'rm -rf "$WRK"' EXIT

echo '==> installing Termux packages'
pkg install -y nodejs zstd patchelf tar curl

echo '==> fetching Alpine musl runtime (pinned + sha256-verified)'
mkdir -p "$MUSL_HOME" "$MUSL_PREFIX"
for pkgname in "${!MUSL_APKS[@]}"; do
  apk="$WRK/$pkgname.apk"
  curl --noproxy '*' -fsSL "$ALPINE_BASE/$pkgname.apk" -o "$apk"
  echo "${MUSL_APKS[$pkgname]}  $apk" | sha256sum -c - \
    || { echo "!! sha256 mismatch for $pkgname.apk — refusing to install"; exit 1; }
  # An .apk is a gzipped tar. Keep lib/ and usr/lib/, drop Alpine's metadata.
  for dest in "$MUSL_HOME" "$MUSL_PREFIX"; do
    tar -xzf "$apk" -C "$dest" --exclude='.PKGINFO' --exclude='.SIGN.RSA.*'
    rm -f "$dest/.PKGINFO" "$dest"/.SIGN.RSA.*
  done
done
[ -e "$MUSL_HOME/lib/ld-musl-aarch64.so.1" ] || { echo '!! musl loader missing after extract'; exit 1; }

echo "==> installing @anthropic-ai/claude-code@$CLAUDE_NPM_VER (npm package + JS shim)"
npm install -g "@anthropic-ai/claude-code@$CLAUDE_NPM_VER"

mkdir -p "$BIN_DIR"
if [ -x "$BIN_DIR/claude-bin" ] && [ "$(cat "$VERSION_FILE" 2>/dev/null)" = "$CLAUDE_SHA256" ] \
   && [ "${FORCE:-0}" != "1" ]; then
  echo '==> pinned claude binary already in place, skipping download (FORCE=1 to refresh)'
else
  echo '==> fetching pinned musl-native claude binary (third-party payload — trust decision)'
  curl --noproxy '*' -fsSL "$REL/claude.bin.zst" -o "$WRK/claude.bin.zst"
  echo "$CLAUDE_SHA256  $WRK/claude.bin.zst" | sha256sum -c - \
    || { echo '!! sha256 mismatch for claude.bin.zst — refusing to install'; exit 1; }
  echo '==> decompressing'
  rm -f "$BIN_DIR/claude-bin"
  zstd -d -f "$WRK/claude.bin.zst" -o "$BIN_DIR/claude-bin"
  chmod +x "$BIN_DIR/claude-bin"
  echo "$CLAUDE_SHA256" > "$VERSION_FILE"
fi

echo '==> patching ELF interpreter + rpath'
patchelf --set-interpreter "$MUSL_HOME/lib/ld-musl-aarch64.so.1" \
  --set-rpath "$MUSL_HOME/lib:$MUSL_PREFIX/lib:$MUSL_PREFIX/usr/lib" \
  "$BIN_DIR/claude-bin"
patchelf --print-interpreter "$BIN_DIR/claude-bin" | grep -q 'ld-musl-aarch64' \
  || { echo '!! interpreter patch did not stick'; exit 1; }

echo '==> writing wrapper ~/.local/bin/claude (DISABLE_AUTOUPDATER=1, LD_PRELOAD cleared)'
# Remove first: a vendor install may have left a symlink here, and writing
# through it would overwrite the vendor binary.
rm -f "$BIN_DIR/claude"
cat > "$BIN_DIR/claude" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
export DISABLE_AUTOUPDATER=1
exec env LD_PRELOAD= "$BIN_DIR/claude-bin" "\$@"
EOF
chmod +x "$BIN_DIR/claude"

case ":$PATH:" in
  *":$BIN_DIR:"*) : ;;
  *) echo "!! $BIN_DIR not in PATH — add it (before \$PREFIX/bin) in your shell rc" ;;
esac

echo '==> done. Run: claude'
