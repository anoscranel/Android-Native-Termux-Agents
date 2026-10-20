#!/data/data/com.termux/files/usr/bin/bash
# Cursor cursor-agent on native Termux — official installer + glibc loaders.
# Device-verified 2026-10-20 (2026.10.19-6bbf2c4 boots + --version prints).
# Idempotent: safe to re-run; re-heals wrappers/patches after Cursor updates.
# Never touches login state, never exports proxies.
set -Eeuo pipefail

PREFIX=/data/data/com.termux/files/usr
HOME_DIR=/data/data/com.termux/files/home
BASE="$HOME_DIR/.local/share/cursor-agent/versions"
BIN_DIR="$HOME_DIR/.local/bin"
LOADER="$PREFIX/glibc/lib/ld-linux-aarch64.so.1"

echo '==> installing Termux packages (incl. glibc runtime)'
pkg install -y curl glibc-repo patchelf
pkg install -y glibc glibc-runner
[ -e "$LOADER" ] || { echo '!! glibc loader missing'; exit 1; }
command -v grun >/dev/null || { echo '!! grun missing (glibc-runner pkg)'; exit 1; }

echo '==> running official Cursor installer (detects linux/arm64 correctly)'
curl --noproxy '*' https://cursor.com/install -fsS | bash

[ -d "$BASE" ] || { echo '!! cursor-agent versions dir not found — official install failed'; exit 1; }
latest="$(ls -1d "$BASE"/*/ 2>/dev/null | sort -V | tail -n1)"
[ -n "$latest" ] && [ -e "$latest/node" ] && [ -e "$latest/index.js" ] \
  || { echo '!! version dir missing bundled node/index.js'; exit 1; }
echo "==> newest version dir: $latest"

# Child-SEA trap: index.js spawns sibling ELF binaries (cursor-agent-sea,
# cursor-agent-worker-sea, cursorsandbox) directly — their PT_INTERP points to
# the Linux default path which does not exist on Android. Point it at Termux's
# glibc loader. (.node shared libs are dlopened by the patched node — no interp.)
echo '==> patching child binaries (glibc interpreter)'
for f in node cursor-agent-sea cursor-agent-worker-sea cursorsandbox; do
  if [ -e "$latest/$f" ]; then
    patchelf --set-interpreter "$LOADER" "$latest/$f" \
      && echo "    patched $f" \
      || echo "    !! patchelf failed for $f (may be static — fine)"
  fi
done

write_wrapper() {
  # $1 = wrapper path
  cat > "$1" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
BASE="$HOME/.local/share/cursor-agent/versions"
latest="$(ls -1d "$BASE"/*/ 2>/dev/null | sort -V | tail -n1)"
# cursor-agent is a bash SEA-launcher for bundled glibc node — run the real
# entrypoint directly through Termux's glibc-runner instead:
exec grun "$latest/node" "$latest/index.js" "$@"
EOF
  chmod +x "$1"
}

mkdir -p "$BIN_DIR"
echo '==> writing glibc-runner wrappers (replace installer symlinks)'
rm -f "$BIN_DIR/cursor-agent"
write_wrapper "$BIN_DIR/cursor-agent"
if [ -L "$BIN_DIR/agent" ] || [ -e "$BIN_DIR/agent" ]; then
  # 'agent' collides with Grok Build's ~/.grok/bin/agent — PATH order decides.
  rm -f "$BIN_DIR/agent"
  write_wrapper "$BIN_DIR/agent"
  echo '==> wrapped ~/.local/bin/agent too (note: collides with Grok Build agent — PATH order decides)'
fi

echo '==> verifying…'
grun "$latest/node" "$latest/index.js" --version \
  || echo '⚠️  cursor staged but did not print --version — see README Limits.'

echo '==> done. Run: cursor-agent login  (then: cursor-agent  — headless: cursor-agent -p "...")'
