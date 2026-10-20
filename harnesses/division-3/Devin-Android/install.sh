#!/data/data/com.termux/files/usr/bin/bash
# Devin for Terminal (Cognition) — Termux glibc-runner install (native-side, NO proot/chroot/VM)
# Manifest-driven: resolves current version + published sha256 from static.devin.ai/cli/current/manifest.json
# Idempotent: safe to re-run. Never touches login/config; never exports proxies.
set -Eeuo pipefail

MANIFEST_URL="${DEVIN_MANIFEST:-https://static.devin.ai/cli/current/manifest.json}"
TARGET="aarch64-unknown-linux"
DEVIN_HOME="$PREFIX/opt/devin"
WRAPPER="$PREFIX/bin/devin"
CURL_AUTH=()
[ -n "${DEVIN_API_KEY:-}" ] && CURL_AUTH=(-H "Authorization: Bearer $DEVIN_API_KEY")

echo "==> Devin for Terminal: Termux glibc-runner install (Native, manifest-resolved)"

echo '==> Enabling Termux glibc repo + tooling…'
pkg install -y glibc-repo glibc glibc-runner curl python >/dev/null
command -v grun >/dev/null || { echo '!! grun missing (glibc-runner pkg) — aborting'; exit 1; }
[ -e "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" ] || { echo '!! glibc loader missing — aborting'; exit 1; }

echo '==> Resolving current version from manifest…'
MANIFEST=$(curl -fsSL "${CURL_AUTH[@]+"${CURL_AUTH[@]}"}" "$MANIFEST_URL")
read VER URL HASH <<<"$(python3 - "$MANIFEST" <<'PY'
import json,sys
d=json.loads(sys.argv[1])
p=d["platforms"]["aarch64-unknown-linux"]
print(d["version"], p["url"], p["sha256"])
PY
)"
[ -n "$VER" ] && [ -n "$HASH" ] || { echo '!! manifest parse failed (target missing?) — aborting'; exit 1; }
echo "    version: $VER"
echo "    sha256 : $HASH"

mkdir -p "$DEVIN_HOME"
STAGE="$DEVIN_HOME/devin-$VER"
BIN="$DEVIN_HOME/bin/devin"

if [ -x "$BIN" ] && [ "$(cat "$DEVIN_HOME/.version" 2>/dev/null)" = "$VER" ] && [ -z "${DEVIN_FORCE:-}" ] && [ -z "${DEVIN_URL:-}" ]; then
  echo "==> devin $VER already staged, skipping download (DEVIN_FORCE=1 to refresh)"
else
  [ -n "${DEVIN_URL:-}" ] && { echo "==> DEVIN_URL override"; URL="$DEVIN_URL"; HASH="${DEVIN_SHA256:-$HASH}"; }
  echo "==> Downloading $URL"
  curl -fsSL "${CURL_AUTH[@]+"${CURL_AUTH[@]}"}" "$URL" -o "$STAGE.tar.gz"
  echo '==> Verifying sha256…'
  echo "$HASH  $STAGE.tar.gz" | sha256sum -c -
  echo '==> Unpacking…'
  tar -xzf "$STAGE.tar.gz" -C "$DEVIN_HOME"
  # tarball ships bin/devin + share/ (docs, man1)
  [ -x "$BIN" ] || { echo '!! expected devin binary missing after unpack'; exit 1; }
  rm -f "$STAGE.tar.gz"
  echo "$VER" > "$DEVIN_HOME/.version"
fi

echo '==> Writing glibc-runner wrapper…'
cat > "$WRAPPER" <<'WEOF'
#!/data/data/com.termux/files/usr/bin/bash
# devin wrapper: run the glibc aarch64 binary via Termux glibc-runner (grun)
exec grun "$PREFIX/opt/devin/bin/devin" "$@"
WEOF
# FUSE quirk: chmod can silently no-op; call twice (harmless)
chmod +x "$WRAPPER" 2>/dev/null || true

echo '==> Verifying…'
grun "$BIN" --version || {
  echo "⚠️  devin staged but failed to run under the glibc loader — see README Limits."
}
echo "==> done. Run: devin"
