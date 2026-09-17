# Antigravity Mac Proxy Auto-Sync Plugin

<p align="center">
  <img src="img/logo.png" alt="Logo" width="100"/>
</p>

<p align="center">
  <b>🚀 Designed for macOS: Force SOCKS5/HTTP proxy for Antigravity without TUN mode, preserving Keychain login sessions.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey" />
  <img src="https://img.shields.io/badge/Antigravity-2.x-blue" />
  <img src="https://img.shields.io/badge/TUN-Not%20Required-green" />
  <img src="https://img.shields.io/badge/license-MIT-blue" />
</p>

<p align="center">
  <a href="README.md">🇨🇳 中文文档</a>
</p>

---

## 📖 The Problem & Our Solution

When using Antigravity (Google's AI coding environment) on macOS:

- 🔴 **Ignoring System Wi-Fi Proxies**: Antigravity's core backend language server (`language_server`, compiled in Go) ignores macOS `scutil --proxy` settings. Without proxy env vars, users in restricted regions are forced to turn on Clash's **TUN mode**.
- 🔴 **Drawbacks of TUN Mode**: Requires root privileges, intercepts global traffic, and conflicts with local Docker/LAN setups.
- 🔴 **The Flaw of External Launchers**: Launching Antigravity directly via detached Unix scripts (`nohup`) detaches the app from the macOS LaunchServices bundle context. Consequently, the macOS Keychain blocks access to the `Antigravity Safe Storage` key, **causing users to be logged out repeatedly (showing the "Welcome to Antigravity / Sign in" screen)**.

### ✨ The Native Solution

Inspection of Antigravity's internal package (`app.asar`) revealed that it natively reads shell environment variables when launching its language server:
```javascript
// Electron apps don't inherit shell environment variables when they are not launched through the terminal.
// We need to load the shell env explicitly so the language server can discover tools in the user's environment.
const env = { ...process.env, ...(0, shell_env_1.shellEnvSync)() };
```
**Antigravity runs a login shell at startup to source `~/.zshrc` and injects those environment variables into `language_server`!**

This plugin takes advantage of this native mechanism:
1. Automatically detects active local proxy ports (Clash Verge, Mihomo, v2rayN, Surge, etc.).
2. Synchronizes a clean, isolated block into `~/.zshrc`.
3. You open Antigravity normally from your Dock or Launchpad — **Keychain remains fully authorized, login state is 100% preserved, and traffic seamlessly routes through your proxy without TUN mode!**

---

## ⚡ Quick Install

### Recommended: One-line Terminal Command (Never prompts "damaged")

Run in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/lz-code-2844/antigravity-mac-proxy-launcher/main/install.sh | bash
```

> 💡 **Why this is recommended**: It compiles the applet locally on your Mac, bypassing macOS Gatekeeper's quarantine attribute and completely preventing the "App is damaged" prompt.

### Option 2: Clone and Install Manually

```bash
git clone https://github.com/lz-code-2844/antigravity-mac-proxy-launcher.git
cd antigravity-mac-proxy-launcher
bash install.sh
```

**The installer automatically:**
1. Installs the global CLI tool `agy-proxy-sync` to `/opt/homebrew/bin` (or `/usr/local/bin`).
2. Creates the **「一键同步VPN代理」** one-click applet on your Desktop.
3. Mounts the Antigravity Agent Skill.
4. Performs an initial proxy detection and writes to `~/.zshrc`.

---

## 🖱️ Usage

### Option 1: Desktop Applet (Easiest)
Whenever you change proxy ports or switch proxy clients, **double-click the "一键同步VPN代理" applet on your Desktop**. It detects and updates your configuration in under a second.

### Option 2: Command Line (CLI)
```bash
# Auto-detect and sync current proxy to ~/.zshrc
agy-proxy-sync

# View current configuration and active proxy status
agy-proxy-sync --status

# Manually specify a port (e.g. 7890)
agy-proxy-sync --port 7890

# Clean/remove the proxy configuration from ~/.zshrc
agy-proxy-sync --clean
```

### Option 3: Antigravity Agent Skill
Inside the Antigravity chat, tell the assistant:
> *"Sync my local proxy configuration"* or *"Update proxy port"*

The agent will invoke the skill automatically.

---

## ❓ FAQ

### Q: "App is damaged and can't be opened. You should move it to the Trash."
**A**: This is macOS Gatekeeper's quarantine mechanism.
* **Why it happens**: When an app is downloaded from a browser (Edge / Chrome / Safari), macOS tags it with the `com.apple.quarantine` extended attribute. Unsigned or ad-hoc signed open-source apps will trigger this prompt.
* **Quick fix**:
  Run this single command in Terminal to strip the quarantine attribute:
  ```bash
  xattr -cr ~/Desktop/一键同步VPN代理.app
  # Or if located in /Applications:
  xattr -cr ~/Applications/一键同步VPN代理.app
  ```
* **Best practice**: Use the **One-line Terminal Command** above, which builds locally and completely avoids quarantine flags.

---

## 📄 License

MIT License. Free for personal and commercial use.
