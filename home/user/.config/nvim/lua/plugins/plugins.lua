return {
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
}
