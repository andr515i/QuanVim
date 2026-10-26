assert(package.loaded["lazyvim.config.autocmds"], "Distribution autocmds must load first")
vim.g.test_autocmds = (vim.g.test_autocmds or 0) + 1
