local function current_file_dir()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return vim.uv.cwd()
  end
  return vim.fn.fnamemodify(path, ":p:h")
end

local function open_explorer_at_current_file()
  local file = vim.api.nvim_buf_get_name(0)
  local cwd = current_file_dir()
  local explorer = Snacks.picker.get({ source = "explorer" })[1]

  if explorer then
    explorer:set_cwd(cwd)
    if file ~= "" then
      pcall(require("snacks.explorer.tree").open, file)
    end
    require("snacks.explorer.actions").update(explorer, {
      target = file ~= "" and file or cwd,
      refresh = true,
    })
    explorer:focus()
  else
    Snacks.explorer({
      cwd = cwd,
      on_show = function(picker)
        if file ~= "" then
          pcall(require("snacks.explorer.tree").open, file)
          require("snacks.explorer.actions").update(picker, {
            target = file,
            refresh = true,
          })
        end
      end,
    })
  end
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>e", open_explorer_at_current_file, desc = "Explorer Snacks (current file dir)" },
      { "<leader>E", open_explorer_at_current_file, desc = "Explorer Snacks (current file dir)" },
      { "<leader>fe", open_explorer_at_current_file, desc = "Explorer Snacks (current file dir)" },
      { "<leader>fE", open_explorer_at_current_file, desc = "Explorer Snacks (current file dir)" },
    },
  },
}
