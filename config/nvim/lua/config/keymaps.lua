vim.keymap.set("n", "<C-ñ>", function()
    local buftype = vim.bo.buftype

    if buftype == "terminal" then
        vim.cmd("bd!")
    else
        vim.cmd("botright 15split | terminal")
    end
end, { desc = "Toggle terminal" })
