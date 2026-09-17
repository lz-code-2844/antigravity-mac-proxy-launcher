-- ============================================================
-- 一键同步 VPN 代理到 ~/.zshrc
-- Antigravity Mac Proxy Auto-Sync Applet
-- ============================================================

try
    -- 查找 agy-proxy-sync 路径
    set cmdPath to ""
    set candidatePaths to {"/opt/homebrew/bin/agy-proxy-sync", "/usr/local/bin/agy-proxy-sync", (POSIX path of (path to home folder)) & ".gemini/antigravity/bin/agy-proxy-sync"}
    
    repeat with p in candidatePaths
        try
            set checkFile to do shell script "test -x " & quoted form of p & " && echo 1 || echo 0"
            if checkFile is "1" then
                set cmdPath to p
                exit repeat
            end if
        end try
    end repeat
    
    if cmdPath is "" then
        display dialog "未找到 agy-proxy-sync 执行文件，请先运行 install.sh 安装。" buttons {"知道了"} default button "知道了" with title "Antigravity 代理同步" with icon stop
        return
    end if
    
    set res to do shell script quoted form of cmdPath
    display dialog res buttons {"好的"} default button "好的" with title "Antigravity 代理同步完成" with icon note
on error errMsg
    display dialog "同步失败: " & errMsg buttons {"知道了"} default button "知道了" with title "Antigravity 代理同步" with icon stop
end try
