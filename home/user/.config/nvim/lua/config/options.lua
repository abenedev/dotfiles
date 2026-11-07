-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

if vim.fn.has("wsl") == 1 then
  -- WSL: use the Windows clipboard.
  -- Spawning powershell.exe costs ~250ms per paste, so prefer win32yank when available.
  if vim.fn.executable("win32yank.exe") == 1 then
    vim.g.clipboard = {
      name = "win32yank-wsl",
      copy = { ["+"] = "win32yank.exe -i --crlf", ["*"] = "win32yank.exe -i --crlf" },
      paste = { ["+"] = "win32yank.exe -o --lf", ["*"] = "win32yank.exe -o --lf" },
      cache_enabled = 1,
    }
  else
    local paste = 'powershell.exe -NoLogo -NoProfile -NonInteractive -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))'
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
      cache_enabled = 1,
    }
  end
elseif vim.env.WAYLAND_DISPLAY then
  -- Arch Linux (Hyprland): use the Wayland clipboard
  vim.g.clipboard = "wl-copy"
end

vim.opt.clipboard = "unnamedplus"
vim.g.autoformat = false
