-- https://wiki.hypr.land/Configuring/Start/
require("default-apps")
require("startup")
require("appearance")
require("input")
require("keybindings")
require("monitors")

hl.config({
    ecosystem = {
        no_update_news = true,
    },
})

hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/ssh-agent.socket")
hl.env("SSH_ASKPASS", os.getenv("HOME") .. "/.local/bin/ssh-askpass.sh")
hl.env("SSH_ASKPASS_REQUIRE", "prefer")
