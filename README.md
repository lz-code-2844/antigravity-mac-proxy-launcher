# Antigravity Mac 代理自动同步插件 (Proxy Auto-Sync)

<p align="center">
  <img src="img/logo.png" alt="Logo" width="100"/>
</p>

<p align="center">
  <b>🚀 专为 macOS 打造：无需 TUN 模式、不掉登录态、自动同步本地 VPN 代理到 Antigravity</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey" />
  <img src="https://img.shields.io/badge/Antigravity-2.x-blue" />
  <img src="https://img.shields.io/badge/TUN-不需要-green" />
  <img src="https://img.shields.io/badge/license-MIT-blue" />
</p>

<p align="center">
  <a href="README_EN.md">🇬🇧 English Version</a>
</p>

---

## 📖 核心痛点与本项目的解决思路

在 macOS 上使用 Antigravity（Google AI 编程编辑器）时，许多国内开发者都会遇到以下痛点：

- 🔴 **不走系统代理**：Antigravity 后端的核心语言服务（Go 编写的 `language_server`）在默认情况下不读取 macOS 系统的 Wi-Fi 代理设置，必须被迫开启 Clash 的 **TUN 模式**。
- 🔴 **TUN 模式副作用大**：需要 root 权限、接管全局网络、容易与本地 Docker/局域网设备冲突。
- 🔴 **外部外挂启动器的硬伤**：如果使用外部脚本或 `nohup` 强行启动二进制文件注入环境变量，会**脱离 macOS 官方 LaunchServices 上下文**，导致系统安全钥匙串（Keychain Safe Storage）拒绝解密凭据，**每次打开都会被强制踢出登录，退回「Welcome to Antigravity / Sign in」界面**。

### ✨ 本项目的终极优雅解法

我们在深入分析 Antigravity 官方核心源码（`app.asar`）时发现，官方早就在代码里内置了环境变量读取机制：
```javascript
// Electron apps don't inherit shell environment variables when they are not launched through the terminal.
// We need to load the shell env explicitly so the language server can discover tools in the user's environment.
const env = { ...process.env, ...(0, shell_env_1.shellEnvSync)() };
```
**Antigravity 启动时，会自动读取用户 `~/.zshrc` 中的环境变量并注入给后台语言服务！**

因此，本项目采用**原生级无损自动同步方案**：
1. 自动探测本地正在运行的代理软件（Clash Verge、Mihomo、v2rayN、Surge 等）及其监听端口。
2. 将标准代理配置以**安全隔离标记块**写入 `~/.zshrc`。
3. **日常照常从 Dock / 启动台正常点击打开 Antigravity** —— 享受官方钥匙串授权，**100% 保持登录态，免 TUN 畅快走代理**！

---

## ✨ 功能特性

| 特性 | 说明 |
| :--- | :--- |
| 🔍 **全自动多重探测** | 自动读取 macOS 系统代理设置、Clash Verge 配置文件，并辅以活跃端口扫描 |
| 🛡️ **安全隔离写入** | 采用 `# >>> Antigravity Proxy Auto-Sync >>>` 独立块，支持反复更新与一键清除，不污染现有环境 |
| 🔑 **永不掉登录态** | 完全走 macOS 原生启动流程，钥匙串授权 100% 正常 |
| 🎛️ **多种交互形态** | 提供终端 CLI 命令、桌面一键点击应用、Antigravity 内置智能体技能三种形态 |
| 🚫 **免 TUN 模式** | Clash 只需开启普通「系统代理」和「规则模式」，轻量省电，不影响其他软件 |

---

## ⚡ 快速安装

### 推荐方式：终端一行命令自动安装（推荐，永不报“已损坏”）

在终端粘贴并回车运行以下命令：

```bash
curl -fsSL https://raw.githubusercontent.com/lz-code-2844/antigravity-mac-proxy-launcher/main/install.sh | bash
```

> 💡 **为什么推荐此方式**：该命令会在您的 Mac 本地直接完成编译与部署，完全避开 macOS 浏览器下载隔离标记（Gatekeeper），**绝不会触发「应用已损坏」的系统误报**！

### 方式二：手动克隆仓库安装

```bash
git clone https://github.com/lz-code-2844/antigravity-mac-proxy-launcher.git
cd antigravity-mac-proxy-launcher
bash install.sh
```

**一键安装程序会自动完成：**
1. 安装全局 CLI 命令 `agy-proxy-sync` 到 `/opt/homebrew/bin`（或 `/usr/local/bin`）。
2. 在桌面生成 **「一键同步VPN代理」** 点击应用。
3. 挂载 Antigravity Agent Skill 技能。
4. 立即执行首次代理探测并写入 `~/.zshrc`。

---

## 🖱️ 使用方法

### 方式 1：桌面一键同步（最轻松）
当您更换了 VPN 节点、代理软件或端口时，**直接双击桌面的「一键同步VPN代理」应用**，1 秒内自动完成探测并在右上角弹出通知。

### 方式 2：终端命令使用
在终端随时输入以下命令：

```bash
# 1. 自动检测并同步当前代理到 ~/.zshrc
agy-proxy-sync

# 2. 查看当前配置与探测状态
agy-proxy-sync --status

# 3. 手动指定端口（例如指定 7890）
agy-proxy-sync --port 7890

# 4. 清理并移除 ~/.zshrc 中的代理配置
agy-proxy-sync --clean
```

### 方式 3：对话内置技能（Antigravity 专属）
在 Antigravity 聊天窗口中，直接对 AI 说：
> *“帮我同步一下本地代理配置”* 或 *“刷新一下代理端口”*

AI 会自动调度该技能完成同步。

---

## 🔧 生成的 `~/.zshrc` 示例

执行后将在您的 `~/.zshrc` 中生成如下标准隔离块：

```bash
# >>> Antigravity Proxy Auto-Sync >>>
# 自动生成于 2026-09-17 22:44:40 (来源: macOS 系统代理配置)
# 专供 Antigravity 免 TUN 模式及终端走代理使用
export HTTP_PROXY="http://127.0.0.1:7897"
export HTTPS_PROXY="http://127.0.0.1:7897"
export ALL_PROXY="socks5://127.0.0.1:7897"
export NO_PROXY="localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,*.local"
# <<< Antigravity Proxy Auto-Sync <<<
```

---

## ❓ 常见问题 (FAQ)

### Q: 双击提示「“一键同步 VPN 代理”已损坏，无法打开。你应该将它移到废纸篓」怎么办？
**A**：这是 macOS 最常见的外来软件拦截机制（Gatekeeper）。
* **原因**：当文件通过浏览器（Edge / Chrome / Safari）下载时，macOS 会自动打上 `com.apple.quarantine`（隔离属性）。如果该软件未购买苹果年费开发者证书签名，系统就会故意弹出误导性的“已损坏”提示。
* **两秒钟解决**：
  在终端执行以下命令，清除隔离属性即可正常打开：
  ```bash
  xattr -cr ~/Desktop/一键同步VPN代理.app
  # 如果应用放到了「应用程序」目录，则执行：
  xattr -cr ~/Applications/一键同步VPN代理.app
  ```
* **一劳永逸建议**：建议其他人直接使用上方的 **「终端一行命令自动安装」**，直接在本地编译，系统天然信任，绝不会跳出损坏弹窗。

### Q: 为什么之前的启动器会导致 Antigravity 退出登录（跳出 Welcome 界面）？
**A**：macOS 将用户的 Google 登录 Token 存放在系统安全钥匙串（Keychain Safe Storage）中，受 App Bundle ID 保护。通过外部脱壳脚本直接运行二进制文件会脱离 LaunchServices 上下文，钥匙串拒绝提供解密密钥，导致被强制登出。而本插件直接写入 `~/.zshrc`，允许您完全从 Dock 正常启动，彻底杜绝此问题。

### Q: Clash Verge 需要开全局模式吗？
**A**：不需要。只需保持常规的「规则模式 (Rule)」并开启「系统代理」即可，局域网和国内流量完全直连，既省电又干净。

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE) 开源，欢迎自由使用、修改与 Star！
