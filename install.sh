#!/usr/bin/env bash
# ==============================================================
# Antigravity Mac Proxy Launcher & Auto-Sync — 一键安装脚本
# https://github.com/lz-code-2844/antigravity-mac-proxy-launcher
# ==============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="一键同步VPN代理"
INSTALL_DIR="$HOME/Applications"
OUTPUT_APP="$INSTALL_DIR/$APP_NAME.app"
DESKTOP_APP="$HOME/Desktop/$APP_NAME.app"

# ---------- 颜色输出 ----------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $*${NC}"; }
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
err()  { echo -e "${RED}❌ $*${NC}"; exit 1; }

echo ""
echo "=================================================="
echo "  Antigravity Mac 代理自动同步插件 — 安装程序"
echo "=================================================="
echo ""

# ---------- 1. 安装 CLI 命令 agy-proxy-sync ----------
echo "📦 步骤 1/4: 安装 CLI 工具 agy-proxy-sync..."

BIN_SRC="$SCRIPT_DIR/bin/agy-proxy-sync"
[ -f "$BIN_SRC" ] || err "找不到 bin/agy-proxy-sync，请确认仓库完整！"

TARGET_BIN=""
if [ -d "/opt/homebrew/bin" ] && [ -w "/opt/homebrew/bin" ]; then
    TARGET_BIN="/opt/homebrew/bin/agy-proxy-sync"
elif [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    TARGET_BIN="/usr/local/bin/agy-proxy-sync"
else
    mkdir -p "$HOME/.local/bin"
    TARGET_BIN="$HOME/.local/bin/agy-proxy-sync"
fi

cp "$BIN_SRC" "$TARGET_BIN"
chmod +x "$TARGET_BIN"
ok "CLI 工具已安装至: $TARGET_BIN"

# ---------- 2. 编译桌面一键点击应用 ----------
echo "📦 步骤 2/4: 编译「一键同步VPN代理」应用..."
mkdir -p "$INSTALL_DIR"

if command -v osacompile &>/dev/null && [ -f "$SCRIPT_DIR/src/sync_applet.applescript" ]; then
    osacompile -o "$OUTPUT_APP" "$SCRIPT_DIR/src/sync_applet.applescript"
    
    # 图标替换
    ICON_SRC="/Applications/Antigravity.app/Contents/Resources/icon.icns"
    if [ -f "$ICON_SRC" ]; then
        cp "$ICON_SRC" "$OUTPUT_APP/Contents/Resources/applet.icns"
    fi
    touch "$OUTPUT_APP"
    
    # 放置到桌面
    rm -rf "$DESKTOP_APP"
    cp -R "$OUTPUT_APP" "$DESKTOP_APP"
    touch "$DESKTOP_APP"
    ok "桌面一键同步应用已生成: $DESKTOP_APP"
else
    warn "未找到 osacompile，跳过桌面应用创建（CLI 命令仍可正常使用）"
fi

# ---------- 3. 注册 Antigravity 智能体技能 ----------
echo "📦 步骤 3/4: 注册 Antigravity Agent Skill..."
SKILL_SRC="$SCRIPT_DIR/skills/proxy-sync/SKILL.md"
SKILL_DST="$HOME/.gemini/config/skills/proxy-sync/SKILL.md"

if [ -f "$SKILL_SRC" ]; then
    mkdir -p "$(dirname "$SKILL_DST")"
    cp "$SKILL_SRC" "$SKILL_DST"
    ok "Antigravity 技能已挂载: $SKILL_DST"
fi

# ---------- 4. 立即执行一次自动同步 ----------
echo "📦 步骤 4/4: 立即探测并同步本地代理到 ~/.zshrc..."
"$TARGET_BIN" || warn "首次探测未发现运行中的代理软件，请启动 Clash 等代理后重新运行"

echo ""
echo "=================================================="
ok "安装全部顺利完成！"
echo "=================================================="
echo ""
echo "✨ 日常使用方式（三选一）："
echo "  1. 🖱️  双击桌面「一键同步VPN代理」图标"
echo "  2. 💻 终端中随时输入: agy-proxy-sync"
echo "  3. 🤖 对 Antigravity 说一句: '帮我同步一下本地代理'"
echo ""
echo "🎉 祝使用愉快！现在可以直接从 Dock 栏正常打开 Antigravity，免 TUN 且绝不掉登录！"
echo ""
