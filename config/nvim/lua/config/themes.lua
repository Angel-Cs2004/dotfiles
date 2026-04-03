vim.g.catppuccin_flavour = "mocha"

require("catppuccin").setup({
  transparent_background = true,
  term_colors = true,
  integrations = {
    telescope = true,
    nvimtree = true,
    neo_tree = true,
    lsp_saga = true,
  },
})

vim.cmd.colorscheme("catppuccin")

local transparent_groups = {
  "Normal",
  "NormalNC",
  "NormalFloat",
  "NvimTreeNormal",
  "NvimTreeNormalNC",
  "NeoTreeNormal",
  "NeoTreeNormalNC",
  "TelescopeNormal",
  "TelescopeBorder",
  "VertSplit",
  "LazyExplorerNormal", -- panel lateral LazyVim
  "LazyExplorerBorder",
}

for _, group in ipairs(transparent_groups) do
  vim.api.nvim_set_hl(0, group, { bg = "NONE" })
end
-- Fuerza transparencia en el Explorer lateral de LazyVim
vim.api.nvim_set_hl(0, "LazyExplorerNormal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "LazyExplorerBorder", { bg = "NONE" })
