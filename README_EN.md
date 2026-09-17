# Antigravity Mac Proxy Launcher

<p align="center">
  <img src="img/logo.png" alt="Logo" width="100"/>
</p>

<p align="center">
  <b>🚀 One-click launch Antigravity with proxy — no TUN mode required. Auto-detects your proxy app and port.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey" />
  <img src="https://img.shields.io/badge/Antigravity-2.x-blue" />
  <img src="https://img.shields.io/badge/TUN-Not%20Required-green" />
  <img src="https://img.shields.io/badge/license-MIT-blue" />
</p>

<p align="center">
  <a href="README.md">🇨🇳 中文</a>
</p>

---

## 📖 Why do you need this?

Antigravity's core backend (`language_server`, written in Go) **does not inherit terminal proxy environment variables** when launched from the Dock or Launchpad. This forces users in restricted networks to enable **TUN mode** in Clash (a system-wide virtual NIC).

TUN mode drawbacks:
- 🔴 Requires root/admin privileges
- 🔴 Proxies ALL traffic (breaks Docker, local dev servers, other VPNs)
- 🔴 Can conflict with other tools

**This launcher's solution**: inject proxy environment variables at launch time using macOS native mechanisms, so Antigravity respects the proxy natively — **no TUN mode needed**.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔍 Auto-detect proxy | Reads macOS system proxy config, identifies running proxy apps |
| 🔄 Port scan fallback | Scans common ports when system proxy isn't configured |
| ✍️ Manual port entry | Allows manual port input when auto-detection fails |
| 🖱️ One-click launch | Confirm detected config and launch Antigravity |
| ❌ One-click close | Close Antigravity only, or Antigravity + proxy together |
| 🔁 Smart toggle | Detects running state and switches between launch/close mode |

**Supported proxy apps:**

| Proxy App | Auto-identified | System proxy | Port scan |
|-----------|----------------|--------------|-----------|
| Clash Verge / Mihomo | ✅ | ✅ | ✅ |
| ClashX / ClashX Pro | ✅ | ✅ | ✅ |
| V2rayN / V2rayU | ✅ | ✅ | ✅ |
| Surge | ✅ | ✅ | ✅ |
| Proxyman | ✅ | ✅ | ✅ |
| ShadowsocksX-NG | ✅ | ✅ | ✅ |
| sing-box / NekoBox | ✅ | ✅ | ✅ |
| Any other proxy | — | ✅ (if system proxy is on) | ✅ |

---

## ⚡ Quick Install

### Option 1: One-line install (recommended)

```bash
git clone https://github.com/lz-code-2844/antigravity-mac-proxy-launcher.git
cd antigravity-mac-proxy-launcher
bash install.sh
```

After installation, an **"Antigravity 代理启动器"** icon will appear on your Desktop.

### Option 2: Manual compile

```bash
osacompile -o ~/Applications/Antigravity\ 代理启动器.app src/launcher.applescript
# Optional: use Antigravity's official icon
cp /Applications/Antigravity.app/Contents/Resources/icon.icns \
   ~/Applications/Antigravity\ 代理启动器.app/Contents/Resources/applet.icns
```

---

## 🖱️ How to Use

### Launch flow

1. **Start your proxy app** (Clash Verge, V2rayN, etc.)
2. **Double-click the launcher icon** on your Desktop

   The launcher auto-detects the proxy and shows a confirmation:
   ```
   ✅ Proxy detected:

   App: Clash Verge
   SOCKS5: 127.0.0.1:7897
   HTTP:   127.0.0.1:7897

   All Antigravity traffic will be routed through the proxy.
   No TUN mode required.
   ```

3. Click **"Launch Antigravity"**

### Close flow

**Double-click the launcher icon again** while Antigravity is running:

- **Close Antigravity**: Quits Antigravity directly. The injected proxy environment variables terminate with the process, while Clash / V2Ray and other system proxy clients remain untouched.
- **Prevent Multi-instance Freeze**: If Antigravity is already running, double-clicking will not spawn a conflicting duplicate instance; instead, it brings the existing window to the front.

### When auto-detection fails

If no port is detected, you'll be prompted to enter the port manually (works with any proxy on any custom port).

---

## 🔧 How Proxy Detection Works

```
1. scutil --proxy  (macOS system proxy settings)
        ↓ not found
2. Identify running proxy app by process name
        ↓ not found
3. Scan common ports (7897/7890/7891/1080/10808 ...)
        ↓ still not found
4. Prompt for manual port entry
```

> **Tip**: Enable "System Proxy" (not TUN) in your proxy app for the most reliable detection.

---

## 🔍 Verify It's Working

After launching, run in Terminal:

```bash
ps eww $(pgrep -x language_server) | tr ' ' '\n' | grep -i proxy
```

Expected output:
```
HTTP_PROXY=http://127.0.0.1:7897
HTTPS_PROXY=http://127.0.0.1:7897
ALL_PROXY=socks5://127.0.0.1:7897
```

---

## ❓ FAQ

### Q: "Cannot verify developer" dialog appears
**A**: Right-click the icon → "Open" → click "Open" again. This is a one-time step.

### Q: "applet wants to control System Events"
**A**: Click "OK". This permission is needed to check if Antigravity is running.

### Q: Antigravity still fails after disabling TUN
**A**: Check that your proxy node actually has access to Google APIs. See [yuaotian/antigravity-proxy](https://github.com/yuaotian/antigravity-proxy) for troubleshooting guides.

### Q: Does this work with the `agy` CLI?
**A**: The CLI natively respects env vars. Just set them in your shell:
```bash
export ALL_PROXY="socks5://127.0.0.1:7897"
agy
```

---

## 🛠️ Project Structure

```
antigravity-mac-proxy-launcher/
├── README.md                  # Chinese docs
├── README_EN.md               # This file
├── install.sh                 # One-click install script
└── src/
    └── launcher.applescript   # Core logic
```

---

## 🙏 Credits

- [yuaotian/antigravity-proxy](https://github.com/yuaotian/antigravity-proxy) — The Windows DLL injection counterpart that inspired this project

---

## 📄 License

MIT License
