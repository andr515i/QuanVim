assert(vim.o.shiftwidth == 2, "Distribution options must load first")
vim.o.shiftwidth = 6
vim.opt.clipboard = "unnamedplus"
if vim.env.QUANVIM_TEST_SCENARIO == "explicit" then
  vim.g.lazyvim_picker = "snacks"
  vim.g.lazyvim_explorer = "snacks"
  vim.g.lazyvim_cmp = "nvim-cmp"
end
