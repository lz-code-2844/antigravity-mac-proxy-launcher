---
name: proxy-sync
description: "Automatically detects local VPN/proxy software (Clash Verge, Mihomo, v2rayN, Surge, etc.) and synchronizes proxy environment variables into ~/.zshrc for seamless Antigravity proxying without TUN mode."
---

# Antigravity Proxy Auto-Sync Skill

Use this skill when the user wants to check, refresh, or synchronize their local VPN/proxy configuration into `~/.zshrc` so that Antigravity and terminal tools can route through the proxy without needing TUN mode.

## Quick CLI Usage

The system has `agy-proxy-sync` installed at `/opt/homebrew/bin/agy-proxy-sync`.

```bash
# 1. 自动检测并写入当前活跃的代理端口到 ~/.zshrc
agy-proxy-sync

# 2. 查看当前 ~/.zshrc 中的代理配置及本地代理状态
agy-proxy-sync --status

# 3. 清除 ~/.zshrc 中的代理配置
agy-proxy-sync --clean

# 4. 手动指定端口（例如指定为 7890）
agy-proxy-sync --port 7890
```

## How It Works

1. Reads macOS system proxy (`scutil --proxy`), Clash Verge configuration (`clash-verge.yaml`), and scans active local ports.
2. Formats a clean, atomic block bounded by `# >>> Antigravity Proxy Auto-Sync >>>` and `# <<< Antigravity Proxy Auto-Sync <<<` inside `~/.zshrc`.
3. When Antigravity launches normally from the macOS Dock or Launchpad, its built-in `shellEnvSync()` automatically reads these variables and supplies them to the underlying language server.
