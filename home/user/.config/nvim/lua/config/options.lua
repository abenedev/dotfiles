-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

if vim.fn.has("wsl") == 1 then
  -- WSL: use the Windows clipboard
  local paste = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))'
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = {
      ["+"] = "clip.exe",
      ["*"] = "clip.exe",
    },
    paste = {
      ["+"] = paste,
      ["*"] = paste,
    },
    cache_enabled = 0,
  }
elseif vim.env.WAYLAND_DISPLAY then
  -- Arch Linux (Hyprland): use the Wayland clipboard
  vim.g.clipboard = "wl-copy"
end

vim.opt.clipboard = "unnamedplus"
vim.g.autoformat = false
