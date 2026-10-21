#!/data/data/com.termux/files/usr/bin/bash
# Opencode (bionic build) installer for native Android Termux — no proot/chroot/VM.
set -Eeuo pipefail

REPO="bd-loser/opencode-bionic"
API="https://api.github.com/repos/${REPO}/releases"
VER="${OPENCODE_VERSION:-}"   # pin: OPENCODE_VERSION=1.18.22 ; default = latest release
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

echo '==>' "opencode-bionic installer (native Termux)"

arch="$(uname -m)"
if [ "$arch" != "aarch64" ]; then
  echo "!! Unsupported arch: $arch — opencode-bionic ships aarch64 only" >&2
  exit 1
fi

command -v curl >/dev/null || { echo '==>' "Installing curl"; pkg install -y curl; }
command -v sha256sum >/dev/null || { echo '==>' "Installing coreutils"; pkg install -y coreutils; }

if [ -n "$VER" ]; then
  echo '==>' "Fetching release ${VER}"
  release_json="$(curl -fsSL "$API/tags/$VER")"
else
  echo '==>' "Resolving latest release"
  release_json="$(curl -fsSL "$API/latest")"
fi

deb_url="$(printf '%s\n' "$release_json" | grep -o '"browser_download_url": *"[^"]*aarch64\.deb"' | head -n1 | grep -o 'https[^"]*' || true)"
if [ -z "$deb_url" ]; then
  echo "!! No aarch64 .deb asset found in that release" >&2
  exit 1
fi
tag="$(printf '%s\n' "$release_json" | grep -o '"tag_name": *"[^"]*"' | head -n1 | sed 's/.*: *"//;s/"$//')"
echo '==>' "Release: ${tag:-unknown}"
echo '==>' "Asset: $deb_url"

tmp="${TMPDIR:-$PREFIX/tmp}/opencode-bionic.$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT
deb="$tmp/$(basename "$deb_url")"

echo '==>' "Downloading"
curl -fsSL "$deb_url" -o "$deb"

# sha256-verify when the release publishes a checksum asset; otherwise warn plainly.
sum_url="$(printf '%s\n' "$release_json" | grep -o '"browser_download_url": *"[^"]*"' | sed 's/.*"\(http[^"]*\)"/\1/' | grep -Ei 'sha256|checksums' | head -n1 || true)"
if [ -n "$sum_url" ]; then
  echo '==>' "Verifying checksum from release asset"
  curl -fsSL "$sum_url" -o "$tmp/checksums"
  want="$(grep -i -- "$(basename "$deb_url")" "$tmp/checksums" | awk '{print $1}' | head -n1)"
  got="$(sha256sum "$deb" | awk '{print $1}')"
  if [ -z "$want" ] || [ "$want" != "$got" ]; then
    echo "!! sha256 mismatch (want=$want got=$got)" >&2
    exit 1
  fi
  echo '==>' "Checksum OK: $got"
else
  echo '⚠️  This release publishes no checksum asset — binary integrity unverified.'
  echo '⚠️  opencode-bionic is a third-party build; installing it is a trust decision.'
fi

echo '==>' "Installing ${deb##*/} via apt (resolves dependencies)"
apt install -y "$deb"

echo '==>' "Verifying install"
opencode --version

echo '==>' "done. Run: opencode"
