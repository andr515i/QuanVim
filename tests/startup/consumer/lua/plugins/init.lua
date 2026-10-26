-- Only QuanVim and Snacks execute. All core/provider specs are still imported.
-- External tools, parsers, completion and LSP activation are outside this fixture.
local disable = {}
for name in pairs(require("lazy.core.config").spec.plugins) do
  if name ~= "QuanVim" and name ~= "snacks.nvim" and name ~= "lazy.nvim" then
    disable[#disable + 1] = { name, enabled = false }
  end
end
return {
  disable,
  {
    "andr515i/QuanVim",
    opts = {
      colorscheme = "habamax",
      news = { lazyvim = false, neovim = false },
    },
  },
  { "folke/snacks.nvim", dir = vim.env.QUANVIM_TEST_ROOT .. "/deps/snacks.nvim", opts = {} },
}
