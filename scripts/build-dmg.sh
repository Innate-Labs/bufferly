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

# 1. 构建 release .app
bash "$ROOT/scripts/build-app.sh"

# 2. 代码签名：有 Developer ID 用之，否则 ad-hoc（Apple Silicon 必须至少 ad-hoc 才能运行）
SIGN_ID="${BUFFERLY_SIGN_IDENTITY:-}"
if [ -z "$SIGN_ID" ]; then
  SIGN_ID="$(security find-identity -v -p codesigning 2>/dev/null | grep -m1 'Developer ID Application' | sed -E 's/.*"(.*)"/\1/' || true)"
fi
if [ -n "$SIGN_ID" ]; then
  echo "==> 用 Developer ID 签名：$SIGN_ID"
  codesign --force --deep --options runtime --sign "$SIGN_ID" "$APP"
else
  echo "==> 无 Developer ID，ad-hoc 签名（本机可运行，分发会有 Gatekeeper 提示）"
  codesign --force --deep --sign - "$APP"
fi

# 3. 准备 DMG 内容：App + Applications 快捷方式
rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# 4. 生成压缩 DMG
hdiutil create \
  -volname "$VOLNAME" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$DMG"

rm -rf "$STAGING"

echo ""
echo "✅ 完成：$DMG"
du -h "$DMG" | cut -f1 | sed 's/^/   体积：/'
