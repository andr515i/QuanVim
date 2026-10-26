assert(package.loaded["lazyvim.config.keymaps"], "Distribution keymaps must load first")
vim.keymap.set("n", "<leader>zt", "<Nop>", { desc = "Personal regression mapping" })
vim.g.test_keymaps = (vim.g.test_keymaps or 0) + 1
