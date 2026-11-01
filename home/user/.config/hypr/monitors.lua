hl.monitor({ output = "eDP-1", mode = "preferred", position = "398x1080",   scale = "auto" })
hl.monitor({ output = "DP-1",  mode = "preferred", position = "1920x0",     scale = "auto" })
hl.monitor({ output = "DP-3",  mode = "preferred", position = "-1080x-420", scale = "auto", transform = 1 })
hl.monitor({ output = "DP-4",  mode = "preferred", position = "0x0",        scale = "auto" })

hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-3",  default = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-4",  default = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-1",  default = true })
