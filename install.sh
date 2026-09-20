#!/usr/bin/env bash
# ==============================================================
# Antigravity Mac Proxy Launcher & Auto-Sync — 一键安装脚本
# 支持直接本地运行，也支持通过 curl -fsSL ... | bash 在线安装
# https://github.com/lz-code-2844/antigravity-mac-proxy-launcher
# ==============================================================
set -euo pipefail

APP_NAME="一键同步VPN代理"
INSTALL_DIR="$HOME/Applications"
OUTPUT_APP="$INSTALL_DIR/$APP_NAME.app"
DESKTOP_APP="$HOME/Desktop/$APP_NAME.app"
REPO_RAW="https://raw.githubusercontent.com/lz-code-2844/antigravity-mac-proxy-launcher/main"

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

# ---------- 准备临时工作目录 ----------
TMP_DIR=""
cleanup() {
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

# 判断是本地克隆目录还是 curl 管道流
LOCAL_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]:-}" ]; then
    LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

BIN_SRC=""
APPLET_SRC=""
SKILL_SRC=""

if [ -n "$LOCAL_DIR" ] && [ -f "$LOCAL_DIR/bin/agy-proxy-sync" ]; then
    BIN_SRC="$LOCAL_DIR/bin/agy-proxy-sync"
    APPLET_SRC="$LOCAL_DIR/src/sync_applet.applescript"
    SKILL_SRC="$LOCAL_DIR/skills/proxy-sync/SKILL.md"
else
    info "正在从 GitHub 获取最新组件..."
    TMP_DIR="$(mktemp -d)"
    curl -fsSL "$REPO_RAW/bin/agy-proxy-sync" -o "$TMP_DIR/agy-proxy-sync"
    curl -fsSL "$REPO_RAW/src/sync_applet.applescript" -o "$TMP_DIR/sync_applet.applescript"
    curl -fsSL "$REPO_RAW/skills/proxy-sync/SKILL.md" -o "$TMP_DIR/SKILL.md"
    BIN_SRC="$TMP_DIR/agy-proxy-sync"
    APPLET_SRC="$TMP_DIR/sync_applet.applescript"
    SKILL_SRC="$TMP_DIR/SKILL.md"
fi

# ---------- 1. 安装 CLI 命令 agy-proxy-sync ----------
echo "📦 步骤 1/4: 安装 CLI 工具 agy-proxy-sync..."

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

if command -v osacompile &>/dev/null && [ -f "$APPLET_SRC" ]; then
    osacompile -o "$OUTPUT_APP" "$APPLET_SRC"
    
    # 替换图标
    ICON_SRC="/Applications/Antigravity.app/Contents/Resources/icon.icns"
    if [ -f "$ICON_SRC" ]; then
        cp "$ICON_SRC" "$OUTPUT_APP/Contents/Resources/applet.icns"
    fi
    
    # 移除隔离属性并重新进行本地 Ad-hoc 签名（防止报“已损坏”）
    xattr -cr "$OUTPUT_APP" 2>/dev/null || true
    codesign --force --deep --sign - "$OUTPUT_APP" 2>/dev/null || true
    touch "$OUTPUT_APP"
    
    # 复制到桌面
    rm -rf "$DESKTOP_APP"
    cp -R "$OUTPUT_APP" "$DESKTOP_APP"
    xattr -cr "$DESKTOP_APP" 2>/dev/null || true
    codesign --force --deep --sign - "$DESKTOP_APP" 2>/dev/null || true
    touch "$DESKTOP_APP"
    ok "桌面一键同步应用已生成: $DESKTOP_APP"
else
    warn "未找到 osacompile，跳过桌面应用创建（CLI 命令仍可正常使用）"
fi

# ---------- 3. 注册 Antigravity 智能体技能 ----------
echo "📦 步骤 3/4: 注册 Antigravity Agent Skill..."
SKILL_DST="$HOME/.gemini/config/skills/proxy-sync/SKILL.md"

if [ -f "$SKILL_SRC" ]; then
    mkdir -p "$(dirname "$SKILL_DST")"
    cp "$SKILL_SRC" "$SKILL_DST"
    ok "Antigravity 技能已挂载: $SKILL_DST"
fi

# ---------- 4. 立即执行一次自动同步 ----------
echo "📦 步骤 4/4: 立即探测并同步本地代理到 ~/.zshrc..."

# 预先检查 ~/.zshrc 权限
if [ -f "$HOME/.zshrc" ]; then
    if [ ! -w "$HOME/.zshrc" ]; then
        warn "检测到 ~/.zshrc 权限不可写，正在尝试修复..."
        chmod u+w "$HOME/.zshrc" 2>/dev/null || true
        if [ ! -w "$HOME/.zshrc" ]; then
            warn "~/.zshrc 所有者可能属于 root，尝试使用 sudo 恢复所有权..."
            sudo chown "$USER" "$HOME/.zshrc" 2>/dev/null || true
            chmod 644 "$HOME/.zshrc" 2>/dev/null || true
        fi
    fi
else
    touch "$HOME/.zshrc" 2>/dev/null || true
fi

if "$TARGET_BIN"; then
    echo ""
    echo "=================================================="
    ok "安装及首次代理同步全部顺利完成！"
    echo "=================================================="
else
    echo ""
    warn "首次同步未完成（若未开启代理软件，请启动 Clash 等代理后运行 'agy-proxy-sync' 重试）。"
    echo "=================================================="
    info "组件已安装完毕（待启动代理后同步）。"
    echo "=================================================="
fi
echo ""
echo "✨ 日常使用方式（三选一）："
echo "  1. 🖱️  双击桌面「一键同步VPN代理」图标"
echo "  2. 💻 终端中随时输入: agy-proxy-sync"
echo "  3. 🤖 对 Antigravity 说一句: '帮我同步一下本地代理'"
echo ""
echo "🎉 祝使用愉快！现在可以直接从 Dock 栏正常打开 Antigravity，免 TUN 且绝不掉登录！"
echo ""
