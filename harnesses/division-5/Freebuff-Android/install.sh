#!/data/data/com.termux/files/usr/bin/bash
# freebuff-android — install Freebuff (CodebuffAI) natively on Android Termux.
# Method: official linux-arm64 tarball + native glibc runtime via `grun`
# (Termux glibc-repo; no proot, no chroot, no VM).
set -Eeuo pipefail

FB_VERSION="${FREEBUFF_VERSION:-0.0.149}"
FB_SHA256="2641083e106b0594b365779833d03022933369b409e9116f332b644949f5c608"
if [ "$FB_VERSION" != "0.0.149" ]; then
  if [ "${FB_UNVERIFIED:-0}" != "1" ]; then
    echo "!! FREEBUFF_VERSION=$FB_VERSION leaves the pinned track — no sha256 is published for other versions." >&2
    echo "!! Refusing to install an unverified binary. If you accept that, re-run with FB_UNVERIFIED=1" >&2
    exit 1
  fi
  FB_SHA256=""
  echo "!! FB_UNVERIFIED=1 — proceeding WITHOUT hash verification (your explicit choice)"
fi
FB_URL="https://codebuff.com/api/releases/download/${FB_VERSION}/freebuff-linux-arm64.tar.gz"
FB_DIR="$HOME/.config/manicode"

echo "==> freebuff-android: init"
[ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "aarch64" ] || {
  echo "!! this installer targets Android aarch64 (Termux) only"; exit 1; }

echo "==> packages (glibc-runner pulls glibc)"
pkg update -y
pkg install -y glibc-repo
pkg install -y glibc glibc-runner tar curl

echo "==> download freebuff ${FB_VERSION} linux-arm64 tarball"
mkdir -p "$FB_DIR" "$TMPDIR"
FB_TGZ="$TMPDIR/freebuff-${FB_VERSION}-linux-arm64.tar.gz"
curl -fsSL --retry 3 -o "$FB_TGZ" "$FB_URL"

if [ -n "$FB_SHA256" ]; then
  echo "==> verify sha256"
  echo "${FB_SHA256}  ${FB_TGZ}" | sha256sum -c -
fi

echo "==> extract into ${FB_DIR}"
tar -xzf "$FB_TGZ" -C "$FB_DIR"
chmod +x "${FB_DIR}/freebuff"
printf '{"version":"%s","target":"linux-arm64"}\n' "$FB_VERSION" > "${FB_DIR}/freebuff-metadata.json"

echo "==> install native launcher (grun wrapper)"
cat > "$PREFIX/bin/freebuff" <<'SH'
#!/data/data/com.termux/files/usr/bin/bash
# Native glibc wrapper — NOT proot. grun is Termux glibc-repo's loader wrapper.
exec grun "$HOME/.config/manicode/freebuff" "$@"
SH
chmod +x "$PREFIX/bin/freebuff"

echo "==> done. Run: freebuff --version   then: freebuff login"
echo "    (move off-pin with: FREEBUFF_VERSION=<v> FB_UNVERIFIED=1 bash install.sh)"
