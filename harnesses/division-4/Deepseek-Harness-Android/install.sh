#!/data/data/com.termux/files/usr/bin/bash
# deepseek-harness-android — DeepSeek Harness (dsh) Web UI, native on Termux.
# Default product install: pnpm workspace in ~/.local/dsh + two source-built
# native deps (node-pty, koffi) + node wrapper. No proot/chroot/VM.
set -Eeuo pipefail

DSH_VERSION="${DSH_VERSION:-0.1.0-rc.6}"
DSH_ROOT="$HOME/.local/dsh"

echo "==> dsh-android: init"
[ "$(uname -m)" = "aarch64" ] || { echo "!! aarch64 (arm64) phones only"; exit 1; }

echo "==> packages"
pkg update -y
pkg install -y nodejs pnpm python make clang cmake curl tar
npm i -g node-gyp 2>/dev/null || true

echo "==> workspace $DSH_ROOT"
mkdir -p "$DSH_ROOT" "$HOME/.local/bin"
cd "$DSH_ROOT"
[ -f package.json ] || printf '{"name":"dsh","version":"1.0.0","private":true,"type":"commonjs"}\n' > package.json

echo "==> add @deepseek-ai/dsh@${DSH_VERSION} (+ @img/sharp-wasm32 shim)"
CYPRESS_INSTALL_BINARY=0 pnpm add "@deepseek-ai/dsh@${DSH_VERSION}" "@img/sharp-wasm32@0.35.3"

echo "==> native dep 1/2: node-pty (source build for bionic)"
NPT_DIR=$(echo "$DSH_ROOT"/node_modules/.pnpm/node-pty@*/node_modules/node-pty)
(cd "$NPT_DIR" && node-gyp rebuild)

echo "==> native dep 2/2: koffi (patch Android statx macro clash, then build)"
KOFFI_DIR=$(echo "$DSH_ROOT"/node_modules/.pnpm/koffi@*/node_modules/koffi)
python3 - "$KOFFI_DIR/lib/native/base/base.cc" <<'PY'
import sys
p = sys.argv[1]
src = open(p).read()
anchor = 'static StatResult StatAt'
i = src.find(anchor)
assert i > 0, 'StatAt not found — koffi layout changed?'
j = src.find('#if defined(__linux__)', i)
assert j > 0
target = '#if defined(__linux__) && !defined(__ANDROID__)'
if target not in src:
    src = src[:j] + src[j:].replace('#if defined(__linux__)', target, 1)
    open(p, 'w').write(src)
    print('koffi base.cc patched @', j)
else:
    print('koffi already patched')
PY
(cd "$KOFFI_DIR" && node ./cnoke.cjs -P . -D src/koffi --prebuild --release)

echo "==> dsh wrapper (~/.local/bin/dsh)"
cat > "$HOME/.local/bin/dsh" <<'SH'
#!/data/data/com.termux/files/usr/bin/env bash
DSH_ROOT="$HOME/.local/dsh"
exec node --expose-internals "$DSH_ROOT/node_modules/@deepseek-ai/dsh/lib/bin.js" "$@"
SH
chmod +x "$HOME/.local/bin/dsh"
if [ "${ADD_TO_PROFILE:-0}" = "1" ]; then
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"; echo '==> added PATH line to ~/.profile';; esac
else
  echo '==> rerun with ADD_TO_PROFILE=1 to append ~/.local/bin to PATH in ~/.profile (default: off)'
fi

echo "==> self-check"
"$HOME/.local/bin/dsh" --version
echo "==> done. Run: dsh web --host 127.0.0.1 --port 3080"
echo "    then open http://127.0.0.1:3080 in your phone browser (dsh web prints the URL)."
