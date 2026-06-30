#!/usr/bin/env bash
# 构建 Bufferly，覆盖安装到 /Applications，验签后启动。
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Bufferly.app"
BUILD_APP="$ROOT_DIR/.build/$APP_NAME"
INSTALL_DIR="${BUFFERLY_INSTALL_DIR:-/Applications}"
INSTALL_APP="$INSTALL_DIR/$APP_NAME"

case "$INSTALL_APP" in
  */Bufferly.app) ;;
  *)
    echo "Refusing to install to unexpected path: $INSTALL_APP" >&2
    exit 1
    ;;
esac

bash "$ROOT_DIR/scripts/build-app.sh"

if pgrep -x Bufferly >/dev/null 2>&1; then
  echo "Quitting running Bufferly..."
  osascript -e 'tell application "Bufferly" to quit' >/dev/null 2>&1 || true

  for _ in {1..20}; do
    if ! pgrep -x Bufferly >/dev/null 2>&1; then
      break
    fi
    sleep 0.1
  done
fi

if pgrep -x Bufferly >/dev/null 2>&1; then
  echo "Bufferly is still running. Quit it and rerun this script." >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_APP"
ditto "$BUILD_APP" "$INSTALL_APP"
codesign --verify --deep --strict "$INSTALL_APP"

open "$INSTALL_APP"
echo "Installed and launched $INSTALL_APP"
