#!/usr/bin/env -S nvim -l

-- scripts/test provisions copies of dependencies and isolates all standard paths.
assert(vim.env.QUANVIM_TEST_ROOT, "Run tests through scripts/test")
local root = vim.env.QUANVIM_TEST_ROOT
for _, name in ipairs({
  "lazy.nvim", "mini.nvim", "plenary.nvim", "mini.icons", "mason.nvim", "mason-lspconfig.nvim", "nvim-treesitter",
}) do
  vim.opt.rtp:append(root .. "/deps/" .. name)
end
vim.opt.rtp:append(vim.uv.cwd())
vim.o.loadplugins = true
dofile("tests/startup/no_install.lua")
require("lazy").setup({
  spec = { { dir = vim.uv.cwd(), name = "QuanVim", lazy = true } },
  root = root .. "/plugins",
  lockfile = root .. "/lazy-lock.json",
  local_spec = false,
  performance = { rtp = { reset = false } },
  install = { missing = false },
  checker = { enabled = false },
  change_detection = { enabled = false },
  pkg = { enabled = false },
  rocks = { enabled = false },
  readme = { enabled = false },
})
_G.LazyVim = require("lazyvim.util")
require("lazyvim.config").get_defaults()
LazyVim.plugin.setup()
assert = require("luassert")
require("mini.test").setup({
  collect = {
    find_files = function()
      return #arg > 0 and arg or vim.fn.globpath("tests", "**/*_spec.lua", true, true)
    end,
  },
})
require("mini.test").run()
