#!/data/data/com.termux/files/usr/bin/bash
# Devin for Terminal (Cognition) — Termux glibc-runner install (native-side, NO proot/chroot/VM)
# Manifest-driven: resolves current version + published sha256 from static.devin.ai/cli/current/manifest.json
# Idempotent: safe to re-run. Never touches login/config; never exports proxies.
set -Eeuo pipefail

MANIFEST_URL="${DEVIN_MANIFEST:-https://static.devin.ai/cli/current/manifest.json}"
TARGET="aarch64-unknown-linux"
DEVIN_HOME="$PREFIX/opt/devin"
WRAPPER="$PREFIX/bin/devin"

# DEVIN_URL pins a specific tarball; it must come with its own DEVIN_SHA256.
if [ -n "${DEVIN_URL:-}" ] && [ -z "${DEVIN_SHA256:-}" ]; then
  echo '!! DEVIN_URL is set but DEVIN_SHA256 is not — refusing to install an unverified tarball' >&2
  exit 1
fi

# Send DEVIN_API_KEY only to devin.ai hosts, never to an override host.
curl_auth_for() { # $1 = URL; fills CURL_AUTH
  local host="${1#*://}"
  host="${host%%[/?#]*}"; host="${host##*@}"; host="${host%%:*}"
  host="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]')"
  CURL_AUTH=()
  if [ -n "${DEVIN_API_KEY:-}" ]; then
    case "$host" in
      devin.ai|*.devin.ai) CURL_AUTH=(-H "Authorization: Bearer $DEVIN_API_KEY") ;;
    esac
  fi
}

echo "==> Devin for Terminal: Termux glibc-runner install (Native, manifest-resolved)"

echo '==> Enabling Termux glibc repo + tooling…'
pkg install -y glibc-repo glibc glibc-runner curl python >/dev/null
command -v grun >/dev/null || { echo '!! grun missing (glibc-runner pkg) — aborting'; exit 1; }
[ -e "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" ] || { echo '!! glibc loader missing — aborting'; exit 1; }

echo '==> Resolving current version from manifest…'
curl_auth_for "$MANIFEST_URL"
MANIFEST=$(curl -fsSL "${CURL_AUTH[@]+"${CURL_AUTH[@]}"}" "$MANIFEST_URL")
read -r VER URL HASH <<<"$(python3 - "$MANIFEST" "$TARGET" <<'PY'
import json,sys
d=json.loads(sys.argv[1])
p=d["platforms"][sys.argv[2]]
print(d["version"], p["url"], p["sha256"])
PY
)"
[ -n "$VER" ] && [ -n "$HASH" ] || { echo '!! manifest parse failed (target missing?) — aborting'; exit 1; }
echo "    version: $VER"
echo "    sha256 : $HASH"

mkdir -p "$DEVIN_HOME"
STAGE="$DEVIN_HOME/devin-$VER"
BIN="$DEVIN_HOME/bin/devin"

STAMP="$VER"
if [ -n "${DEVIN_URL:-}" ]; then
  echo "==> DEVIN_URL override (verified against DEVIN_SHA256)"
  URL="$DEVIN_URL"; HASH="$DEVIN_SHA256"; STAMP="custom-$DEVIN_SHA256"
fi

if [ -x "$BIN" ] && [ "$(cat "$DEVIN_HOME/.version" 2>/dev/null)" = "$STAMP" ] && [ -z "${DEVIN_FORCE:-}" ]; then
  echo "==> devin $STAMP already staged, skipping download (DEVIN_FORCE=1 to refresh)"
else
  echo "==> Downloading $URL"
  curl_auth_for "$URL"
  curl -fsSL "${CURL_AUTH[@]+"${CURL_AUTH[@]}"}" "$URL" -o "$STAGE.tar.gz"
  echo '==> Verifying sha256…'
  echo "$HASH  $STAGE.tar.gz" | sha256sum -c -
  echo '==> Unpacking…'
  tar -xzf "$STAGE.tar.gz" -C "$DEVIN_HOME"
  # tarball ships bin/devin + share/ (docs, man1)
  [ -x "$BIN" ] || { echo '!! expected devin binary missing after unpack'; exit 1; }
  rm -f "$STAGE.tar.gz"
  echo "$STAMP" > "$DEVIN_HOME/.version"
fi

echo '==> Writing glibc-runner wrapper…'
rm -f "$WRAPPER"
cat > "$WRAPPER" <<'WEOF'
#!/data/data/com.termux/files/usr/bin/bash
# devin wrapper: run the glibc aarch64 binary via Termux glibc-runner (grun)
exec grun "$PREFIX/opt/devin/bin/devin" "$@"
WEOF
chmod +x "$WRAPPER"

echo '==> Verifying…'
grun "$BIN" --version || {
  echo "⚠️  devin staged but failed to run under the glibc loader — see README Limits."
}
echo "==> done. Run: devin"
