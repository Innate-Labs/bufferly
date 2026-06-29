#!/usr/bin/env bash
# 把 Bufferly 打包成可分发的 .dmg（拖到 Applications 安装）。
#
# 注意：本机若无 Developer ID 证书，仅做 ad-hoc 签名 —— 本机可运行，
# 但首次打开需右键「打开」绕过 Gatekeeper；正经零警告分发需 Developer ID + 公证。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.build/Bufferly.app"
DMG="$ROOT/.build/Bufferly.dmg"
STAGING="$ROOT/.build/dmg-staging"
VOLNAME="Bufferly"

# 1. 构建并签名 release .app
bash "$ROOT/scripts/build-app.sh"

# 2. 准备 DMG 内容：App + Applications 快捷方式
rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# 3. 生成压缩 DMG
hdiutil create \
  -volname "$VOLNAME" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$DMG"

rm -rf "$STAGING"

echo ""
echo "✅ 完成：$DMG"
du -h "$DMG" | cut -f1 | sed 's/^/   体积：/'
