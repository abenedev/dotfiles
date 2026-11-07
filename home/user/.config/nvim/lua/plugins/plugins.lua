return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    priority = 1000,
    config = function()
      require("github-theme").setup({
        palettes = {
          github_dark = {
            canvas = {
              default = "#000000",
            },
          },
        },
      })
      vim.cmd("colorscheme github_dark")

      -- Set snacks explorer (file tree) background to pure black
      local function set_explorer_bg()
        vim.api.nvim_set_hl(0, "SnacksPickerList", { bg = "#000000" })
        vim.api.nvim_set_hl(0, "SnacksNormal", { bg = "#000000" })
        vim.api.nvim_set_hl(0, "SnacksNormalNC", { bg = "#000000" })
      end
      set_explorer_bg()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_explorer_bg,
      })
    end,
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true, -- Show dotfiles in the explorer
            ignored = true, -- Show gitignored files in the explorer
            exclude = { ".git", "node_modules", ".venv", "target", "__pycache__" },
          },
          files = {
            hidden = true, -- Show dotfiles in the file picker
            ignored = true, -- Show gitignored files in the file picker
            exclude = { ".git", "node_modules", ".venv", "target", "__pycache__" },
          },
        },
      },
    },
  },
  {
    -- Reading the system clipboard on WSL spawns powershell.exe, which freezes nvim
    "gbprod/yanky.nvim",
    opts = {
      system_clipboard = { sync_with_ring = false },
    },
  },
  {
    "okuuva/auto-save.nvim",
    lazy = false,
    opts = {
      enabled = true,
      debounce_delay = 2000, -- Delay in milliseconds
      trigger_events = { immediate_save = { "BufLeave", "FocusLost" }, defer_save = { "InsertLeave" } },
    },
    keys = {
      { "<leader>uv", "<cmd>ASToggle<CR>", desc = "Toggle autosave" },
    },
  },
}
