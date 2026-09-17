#!/usr/bin/env bash
# ==============================================================
# Antigravity Mac Proxy Launcher — 一键安装脚本
# https://github.com/YOUR_USERNAME/antigravity-mac-proxy-launcher
# ==============================================================
set -euo pipefail

APP_NAME="Antigravity 代理启动器"
INSTALL_DIR="$HOME/Applications"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/src/launcher.applescript"
OUTPUT="$INSTALL_DIR/$APP_NAME.app"

# ---------- 颜色输出 ----------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
err()  { echo -e "${RED}❌ $*${NC}"; exit 1; }

echo ""
echo "=================================================="
echo "  Antigravity Mac 代理启动器 — 安装程序"
echo "=================================================="
echo ""

# ---------- 检查必要条件 ----------
[ -f "$SRC" ] || err "找不到 src/launcher.applescript，请确认已完整克隆仓库"
[ -d "/Applications/Antigravity.app" ] || warn "未检测到 Antigravity.app，请确认已安装 Antigravity"
command -v osacompile &>/dev/null || err "缺少 osacompile，请确认系统已安装 macOS Command Line Tools"

# ---------- 创建安装目录 ----------
mkdir -p "$INSTALL_DIR"

# ---------- 编译 AppleScript → .app ----------
echo "📦 正在编译启动器..."
osacompile -o "$OUTPUT" "$SRC"
ok "编译完成"

# ---------- 替换图标 ----------
ICON_SRC="/Applications/Antigravity.app/Contents/Resources/icon.icns"
ICON_DST="$OUTPUT/Contents/Resources/applet.icns"

if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$ICON_DST"
    ok "已使用 Antigravity 官方图标"
else
    warn "未找到 Antigravity 图标，使用默认图标"
fi

# ---------- 刷新 LaunchServices 图标缓存 ----------
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [ -f "$LSREGISTER" ]; then
    "$LSREGISTER" -f "$OUTPUT" 2>/dev/null || true
fi
touch "$OUTPUT"

# ---------- 也在桌面创建替身（可选）----------
DESKTOP_ALIAS="$HOME/Desktop/$APP_NAME.app"
if [ ! -e "$DESKTOP_ALIAS" ]; then
    osascript -e "tell application \"Finder\" to make alias file to POSIX file \"$OUTPUT\" at POSIX file \"$HOME/Desktop/\"" 2>/dev/null || \
    ln -s "$OUTPUT" "$DESKTOP_ALIAS" 2>/dev/null || true
fi

echo ""
ok "安装完成！"
echo ""
echo "  📍 安装位置：$OUTPUT"
echo "  🖥️  桌面快捷方式：$DESKTOP_ALIAS"
echo ""
echo "  使用方法："
echo "  1. 启动你的代理软件（Clash Verge / V2rayN / Surge 等）"
echo "  2. 双击桌面的「Antigravity 代理启动器」图标"
echo "  3. 启动器会自动检测代理端口，确认后启动 Antigravity"
echo ""
echo "  如遇「无法验证开发者」提示："
echo "  → 右键图标 → 选「打开」→ 再次点「打开」"
echo ""
