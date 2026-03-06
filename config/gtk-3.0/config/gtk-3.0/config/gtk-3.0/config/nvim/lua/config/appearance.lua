local M = {}

function M.setup()
  vim.o.background = "dark"
  vim.o.number = true
  vim.o.relativenumber = true
  vim.o.cursorline = true
  vim.cmd.colorscheme("catppuccin")
end

return M
