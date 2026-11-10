local apps = require("default-apps")

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Launchers
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(apps.appLauncher))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(apps.webBrowser))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("discord"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(apps.fileExplorer))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(apps.terminal))
hl.bind("Control_L + Shift_L + escape", hl.dsp.exec_cmd(apps.taskManager), { release = true })
hl.bind(mainMod .. " + Shift_L + S", hl.dsp.exec_cmd(apps.screenshot), { release = true })

-- Window management
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind("F11", hl.dsp.window.fullscreen({ mode = "fullscreen" })) -- Toggle the window between focus and fullscreen

-- Switch between the dark and light themes
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.local/bin/theme.sh"))

-- Move focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

-- Move focused window
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + ALT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + ALT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + ALT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + ALT + L", hl.dsp.window.move({ direction = "right" }))

-- Resize focused window
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + SHIFT + H", hl.dsp.window.resize({ x = -10, y = 0,   relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.resize({ x = 0,   y = 10,  relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.resize({ x = 0,   y = -10, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.resize({ x = 10,  y = 0,   relative = true }), { repeating = true })

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
local workspaceKeys = { "ampersand", "eacute", "quotedbl", "apostrophe", "parenleft", "minus", "egrave", "underscore", "ccedilla", "agrave" }
for i, key in ipairs(workspaceKeys) do
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

-- Brightness control
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("~/.local/bin/brightnesscontrol.sh i"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.local/bin/brightnesscontrol.sh d"), { locked = true, repeating = true })

-- Volume control
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.local/bin/volumecontrol.sh -o i"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.local/bin/volumecontrol.sh -o d"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("~/.local/bin/volumecontrol.sh -o m"), { locked = true })

-- Lock
-- Lid switch: "on" = closed, "off" = opened. On AC, ac-no-sleep.sh stops logind from suspending on close,
-- so lock and turn the internal screen off instead (processes keep running).
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("hyprctl dispatch dpms off eDP-1; ~/.local/bin/lock-screen.sh"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl dispatch dpms on eDP-1"), { locked = true })
hl.bind(mainMod .. " + F12", hl.dsp.exec_cmd("~/.local/bin/lock-screen.sh"))
