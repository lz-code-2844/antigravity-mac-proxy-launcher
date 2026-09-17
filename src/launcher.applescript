-- ============================================================
-- Antigravity Mac Proxy Launcher
-- https://github.com/YOUR_USERNAME/antigravity-mac-proxy-launcher
--
-- 功能 / Features:
--   · 自动检测本机代理软件及端口 / Auto-detect proxy app & port
--   · 以代理环境变量启动 Antigravity / Launch with proxy env vars
--   · 一键关闭 Antigravity 和/或代理 / Close Antigravity and/or proxy
--   · 无需 TUN 模式 / No TUN mode required
-- ============================================================

-- 全局：状态文件路径（用于记录本次是否由启动器启动）
property stateFile : "/tmp/.antigravity_proxy_launcher_state"

-- ============================================================
-- 【主入口】
-- ============================================================
on run
    set isRunning to my isAntigravityRunning()
    set wasLaunchedByUs to my isLaunchedByUs()

    if isRunning then
        my handleRunning(wasLaunchedByUs)
    else
        my handleStopped()
    end if
end run

-- ============================================================
-- Antigravity 正在运行时的处理
-- ============================================================
on handleRunning(wasLaunchedByUs)
    if wasLaunchedByUs then
        -- 由本启动器以代理模式启动
        set savedInfo to my readState()
        set msg to "Antigravity 当前以「代理模式」运行中。" & return & return & savedInfo & return & return & "请选择操作："
        set response to button returned of (display dialog msg buttons {"取消", "仅关闭 Antigravity", "关闭 Antigravity 和代理"} default button "仅关闭 Antigravity" with title "Antigravity 代理启动器" with icon caution)

        if response is "仅关闭 Antigravity" then
            my closeAntigravity()
            display notification "Antigravity 已关闭，代理软件仍在运行" with title "Antigravity 代理启动器"

        else if response is "关闭 Antigravity 和代理" then
            my closeAntigravity()
            my closeProxyApps()
            display notification "Antigravity 和代理软件均已关闭" with title "Antigravity 代理启动器"
        end if

    else
        -- 由用户直接启动（普通模式）
        set response to button returned of (display dialog "Antigravity 当前以「普通模式」运行（未经代理启动器启动）。" & return & return & "可关闭后以代理模式重新启动，以避免开启 TUN 模式。" buttons {"取消", "仅关闭", "关闭后以代理模式重启"} default button "关闭后以代理模式重启" with title "Antigravity 代理启动器" with icon note)

        if response is "仅关闭" then
            my closeAntigravity()
            display notification "Antigravity 已关闭" with title "Antigravity 代理启动器"

        else if response is "关闭后以代理模式重启" then
            my closeAntigravity()
            delay 1.5
            my handleStopped()
        end if
    end if
end handleRunning

-- ============================================================
-- Antigravity 未运行时的处理（检测代理并启动）
-- ============================================================
on handleStopped()
    set proxyData to my detectProxy()
    set socksPort to item 1 of proxyData
    set httpPort to item 2 of proxyData
    set proxyHost to item 3 of proxyData
    set detectedApp to item 4 of proxyData

    -- 未检测到可用端口
    if socksPort is "" and httpPort is "" then
        set response to button returned of (display dialog "⚠️ 未检测到正在运行的代理软件。" & return & return & "支持的代理软件：" & return & "  Clash Verge / ClashX / ClashX Pro" & return & "  V2rayN / V2rayU" & return & "  Surge / Proxyman" & return & "  Shadowsocks / ShadowsocksX-NG" & return & "  sing-box / NekoBox" & return & return & "请先启动代理软件并开启「系统代理」，或手动输入端口。" buttons {"取消", "手动输入端口"} default button "取消" with title "Antigravity 代理启动器" with icon stop)

        if response is "手动输入端口" then
            set dlg to display dialog "请输入代理端口号：" & return & "(例如：7890, 7891, 7897, 1080)" default answer "7890" buttons {"取消", "确认"} default button "确认" with title "手动输入端口"
            if button returned of dlg is "取消" then return
            set manualPort to my trimText(text returned of dlg)
            if manualPort is "" then return
            set socksPort to manualPort
            set httpPort to manualPort
            set detectedApp to "手动输入"
        else
            return
        end if
    end if

    -- 如果只有 HTTP 端口，SOCKS5 也用它（混合端口同时支持两种协议）
    if socksPort is "" then set socksPort to httpPort
    if httpPort is "" then set httpPort to socksPort

    -- 显示检测结果并确认
    set confirmMsg to "✅ 检测到代理配置：" & return & return & "代理软件：" & detectedApp & return & "SOCKS5 端口：127.0.0.1:" & socksPort & return & "HTTP 端口：127.0.0.1:" & httpPort & return & return & "启动后 Antigravity 的所有流量将强制走代理，" & return & "无需开启 TUN 模式。"

    set response to button returned of (display dialog confirmMsg buttons {"取消", "启动 Antigravity"} default button "启动 Antigravity" with title "Antigravity 代理启动器" with icon note)

    if response is "启动 Antigravity" then
        -- 用环境变量方式启动
        do shell script "env HTTP_PROXY='http://" & proxyHost & ":" & httpPort & "' HTTPS_PROXY='http://" & proxyHost & ":" & httpPort & "' ALL_PROXY='socks5://" & proxyHost & ":" & socksPort & "' open -a '/Applications/Antigravity.app' 2>/dev/null &"

        -- 保存本次启动状态
        do shell script "printf 'proxy_launched=1\\napp=" & detectedApp & "\\nsocks_port=" & socksPort & "\\nhttp_port=" & httpPort & "' > " & stateFile

        delay 1
        display notification "代理模式已启动 ✓" with title "Antigravity 代理启动器" subtitle detectedApp & " · SOCKS5 端口 " & socksPort
    end if
end handleStopped

-- ============================================================
-- 自动检测代理软件和端口
-- 检测顺序：
--   1. macOS 系统代理配置（scutil --proxy）← 最准确
--   2. 识别正在运行的代理进程名
--   3. 扫描常用端口（兜底）
-- ============================================================
on detectProxy()
    set socksPort to ""
    set httpPort to ""
    set proxyHost to "127.0.0.1"
    set detectedApp to "未知"

    -- ---- 步骤 1：读取 macOS 系统代理配置 ----
    try
        set proxyRaw to do shell script "scutil --proxy 2>/dev/null"

        if proxyRaw contains "SOCKSEnable : 1" then
            set socksPort to do shell script "echo " & quoted form of proxyRaw & " | awk '/SOCKSPort/{print $3}'"
            set socksPort to my trimText(socksPort)
        end if

        if proxyRaw contains "HTTPEnable : 1" then
            set httpPort to do shell script "echo " & quoted form of proxyRaw & " | awk '/HTTPPort/{print $3}'"
            set httpPort to my trimText(httpPort)
        end if
    end try

    -- ---- 步骤 2：识别代理软件进程 ----
    try
        set procList to do shell script "ps -eo comm 2>/dev/null | sort -u"

        if procList contains "clash-verge" or procList contains "verge-mihomo" then
            set detectedApp to "Clash Verge"
        else if procList contains "ClashX Pro" then
            set detectedApp to "ClashX Pro"
        else if procList contains "ClashX" then
            set detectedApp to "ClashX"
        else if procList contains "mihomo" then
            set detectedApp to "Mihomo (Clash Meta)"
        else if procList contains "v2rayN" or procList contains "V2rayN" then
            set detectedApp to "V2rayN"
        else if procList contains "v2rayU" then
            set detectedApp to "V2rayU"
        else if procList contains "Surge" then
            set detectedApp to "Surge"
        else if procList contains "Proxyman" then
            set detectedApp to "Proxyman"
        else if procList contains "ShadowsocksX" then
            set detectedApp to "ShadowsocksX-NG"
        else if procList contains "shadowsocks" then
            set detectedApp to "Shadowsocks"
        else if procList contains "sing-box" then
            set detectedApp to "sing-box"
        else if procList contains "NekoBox" then
            set detectedApp to "NekoBox"
        end if
    end try

    -- ---- 步骤 3：如果系统代理未配置，扫描常用端口 ----
    if socksPort is "" and httpPort is "" then
        set portList to {"7897", "7890", "7891", "1080", "10808", "10809", "6153", "2080", "2081", "1089", "8889", "20170", "20171"}
        repeat with p in portList
            try
                set isOpen to do shell script "nc -z -w1 127.0.0.1 " & p & " 2>/dev/null && echo 1 || echo 0"
                if isOpen is "1" then
                    set socksPort to p
                    set httpPort to p
                    exit repeat
                end if
            end try
        end repeat
    end if

    return {socksPort, httpPort, proxyHost, detectedApp}
end detectProxy

-- ============================================================
-- 关闭 Antigravity 及清理状态文件
-- ============================================================
on closeAntigravity()
    do shell script "pkill -a -i 'Antigravity' 2>/dev/null; rm -f " & stateFile & "; true"
    delay 0.8
end closeAntigravity

-- ============================================================
-- 关闭常见代理软件
-- ============================================================
on closeProxyApps()
    set proxyApps to {"Clash Verge", "ClashX", "ClashX Pro", "v2rayN", "V2rayU", "Surge", "Proxyman", "ShadowsocksX-NG", "NekoBox"}
    repeat with appName in proxyApps
        try
            do shell script "osascript -e 'quit app \"" & appName & "\"' 2>/dev/null; true"
        end try
    end repeat
    do shell script "pkill -f 'verge-mihomo|mihomo|sing-box|xray|v2ray' 2>/dev/null; true"
    delay 0.8
end closeProxyApps

-- ============================================================
-- 判断 Antigravity 是否正在运行
-- ============================================================
on isAntigravityRunning()
    try
        set r to do shell script "pgrep -x Antigravity 2>/dev/null | wc -l | tr -d ' '"
        if r as integer > 0 then return true
    end try
    return false
end isAntigravityRunning

-- ============================================================
-- 判断是否由本启动器（代理模式）启动
-- ============================================================
on isLaunchedByUs()
    try
        set r to do shell script "grep -c 'proxy_launched=1' " & stateFile & " 2>/dev/null || echo 0"
        if r as integer > 0 then return true
    end try
    return false
end isLaunchedByUs

-- ============================================================
-- 读取状态文件（用于显示当前代理信息）
-- ============================================================
on readState()
    try
        set appName to do shell script "grep '^app=' " & stateFile & " | cut -d= -f2"
        set sPort to do shell script "grep '^socks_port=' " & stateFile & " | cut -d= -f2"
        set hPort to do shell script "grep '^http_port=' " & stateFile & " | cut -d= -f2"
        return "代理软件：" & appName & return & "SOCKS5 端口：127.0.0.1:" & sPort & return & "HTTP 端口：127.0.0.1:" & hPort
    end try
    return "代理信息不可用"
end readState

-- ============================================================
-- 去除字符串首尾空白
-- ============================================================
on trimText(t)
    repeat while t starts with " " or t starts with tab or t starts with return
        set t to text 2 thru -1 of t
    end repeat
    repeat while t ends with " " or t ends with tab or t ends with return
        set t to text 1 thru -2 of t
    end repeat
    return t
end trimText
