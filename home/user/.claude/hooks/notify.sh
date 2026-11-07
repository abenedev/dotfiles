#!/bin/bash
# Claude Code Notification hook: desktop notification when Claude needs attention.
# WSL: Windows toast via powershell.exe. Linux: notify-send (dunst).
msg=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("message",""))' 2>/dev/null)
[ -z "$msg" ] && msg="Claude Code needs your attention"

if grep -qi microsoft /proc/version 2>/dev/null; then
    export CLAUDE_NOTIFY_MSG="$msg"
    powershell.exe -NoLogo -NoProfile -NonInteractive -Command '
$m = $env:CLAUDE_NOTIFY_MSG
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
$t = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
$n = $t.GetElementsByTagName("text")
$n.Item(0).AppendChild($t.CreateTextNode("Claude Code")) > $null
$n.Item(1).AppendChild($t.CreateTextNode($m)) > $null
$id = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($id).Show([Windows.UI.Notifications.ToastNotification]::new($t))
' >/dev/null 2>&1
elif command -v notify-send > /dev/null; then
    notify-send -a "Claude Code" -u normal "Claude Code" "$msg"
fi
exit 0
