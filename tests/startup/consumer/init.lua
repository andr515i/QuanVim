local repo = vim.env.QUANVIM_TEST_REPO
local scenario = vim.env.QUANVIM_TEST_SCENARIO
local root = vim.env.QUANVIM_TEST_ROOT
local errors = {}
local notify = vim.notify
vim.notify = function(msg, level, opts)
  if level == vim.log.levels.ERROR or level == "error" then
    errors[#errors + 1] = tostring(msg)
  end
  notify(msg, level, opts)
end
vim.opt.rtp:prepend(vim.fn.stdpath("config"))
vim.opt.rtp:prepend(root .. "/deps/lazy.nvim")
dofile(repo .. "/tests/startup/no_install.lua")
vim.fn.writefile({ vim.json.encode({
  version = 8,
  install_version = (scenario == "old" or scenario == "explicit") and 7 or 8,
  extras = {},
}) }, vim.fn.stdpath("config") .. "/lazyvim.json")

-- Observe the real loader before setup, without putting QuanVim on runtimepath.
assert(not vim.tbl_contains(vim.opt.rtp:get(), repo))
vim.loader.enable()
local find = vim.loader.find
local found_extra = false
vim.loader.find = function(name, opts)
  local result = find(name, opts)
  if name:find("^lazyvim%.plugins%.extras%.") then
    assert(vim.tbl_contains(vim.opt.rtp:get(), repo), "QuanVim runtimepath missing before extra lookup")
    if name == "lazyvim.plugins.extras.lang.json" then
      assert(result[1] and result[1].modpath:find(repo, 1, true), "Extra resolved outside QuanVim")
      found_extra = true
    end
  end
  return result
end

require("lazy").setup({
  spec = {
    { "andr515i/QuanVim", dir = repo, import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "plugins" },
  },
  root = vim.fn.stdpath("data") .. "/lazy",
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  local_spec = false,
  install = { missing = false },
  checker = { enabled = false },
  change_detection = { enabled = false },
  pkg = { enabled = false },
  rocks = { enabled = false },
  readme = { enabled = false },
})

local Config = require("lazy.core.config")
assert(Config.plugins.QuanVim and Config.plugins.QuanVim.dir == repo, "Wrong distribution identity")
assert(Config.plugins.QuanVim._.loaded, "QuanVim did not load")
assert(not Config.plugins.LazyVim, "Upstream distribution is registered")
for name, plugin in pairs(Config.plugins) do
  if plugin._.loaded then
    assert(name == "QuanVim" or name == "snacks.nvim" or name == "lazy.nvim", "Unexpected activation: " .. name)
  end
end
assert(found_extra, "Extra lookup was not exercised")
assert(vim.o.shiftwidth == 6, "Personal option override lost")
assert(vim.g.test_autocmds == (scenario == "lua" and 1 or nil), "Wrong early autocmd phase")
assert(not vim.g.test_keymaps, "Keymaps must be deferred")
local old = scenario == "old"
assert(LazyVim.config.get_default("picker").name == (old and "fzf" or "snacks"))
assert(LazyVim.config.get_default("explorer").name == (old and "neo-tree" or "snacks"))
assert(LazyVim.config.get_default("cmp").name == (scenario == "explicit" and "nvim-cmp" or "blink.cmp"))
if scenario == "explicit" then
  for _, group in ipairs({ "picker", "explorer", "cmp" }) do
    assert(LazyVim.config.get_default(group).origin == "global", "Explicit provider choice was ignored")
  end
end

-- Headless startup need not enter a UI. Deliberately trigger the real deferred
-- callback once after VimEnter, then allow scheduled callbacks/errors to drain.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      local ok, err = xpcall(function()
        if not vim.g.test_keymaps then
          vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
        end
        assert(vim.g.test_autocmds == 1 and vim.g.test_keymaps == 1, "Deferred config did not run exactly once")
        assert(vim.fn.exists(":LazyExtras") == 2 and vim.fn.exists(":LazyHealth") == 2)
        assert(vim.fn.exists(":LazyFormat") == 2)
        assert(vim.fn.maparg("<leader>zt", "n", false, true).desc == "Personal regression mapping")
        assert(vim.o.clipboard == "unnamedplus", "Deferred clipboard restoration lost")
        if scenario == "lua" then
          assert(vim.bo.filetype == "lua", "Lua file was not opened")
        end
        if scenario == "missing" then
          local spec = require("lazy.core.plugin").Spec.new({ import = "lazyvim.plugins.extras.missing_regression" })
          local message = vim.inspect(spec.notifs)
          assert(message:find("lazyvim.plugins.extras.missing_regression", 1, true), message)
          assert(message:find("not found on runtimepath", 1, true), message)
          assert(not message:find("bad argument", 1, true), message)
        end
        assert(#Config.spec.notifs == 0, vim.inspect(Config.spec.notifs))
      end, debug.traceback)
      if not ok then
        io.stderr:write(err .. "\n")
        vim.cmd("cquit 1")
        return
      end
      vim.defer_fn(function()
        local messages = vim.api.nvim_exec2("messages", { output = true }).output
        -- Snacks replaces vim.notify during setup. Include its history so
        -- queued startup errors cannot disappear into a notification window.
        for _, notification in ipairs(Snacks.notifier.get_history({ filter = vim.log.levels.ERROR })) do
          errors[#errors + 1] = notification.msg
        end
        if #errors > 0 or vim.v.errmsg ~= "" or messages:find("Error") or messages:find("E%d+:") then
          io.stderr:write(vim.inspect(errors) .. "\n" .. vim.v.errmsg .. "\n" .. messages)
          vim.cmd("cquit 1")
          return
        end
        io.stdout:write("STARTUP OK " .. scenario .. "\n")
        vim.cmd("qa!")
      end, 700)
    end)
  end,
})
