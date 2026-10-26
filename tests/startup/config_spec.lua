local Plugin = require("lazy.core.plugin")

describe("Configuration contracts", function()
  it("refuses plugin management tasks", function()
    local ok, err = pcall(function()
      require("lazy.manage").run({})
    end)
    assert.is_false(ok)
    assert.is_true(err:find("Plugin management is forbidden", 1, true) ~= nil, err)
  end)

  it("opts mutation preserves inherited nested settings", function()
    local spec = Plugin.Spec.new({
      { import = "lazyvim.plugins.extras.lang.dotnet" },
      {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
          opts.servers.omnisharp.enable_roslyn_analyzers = false
        end,
      },
    })
    assert.same({}, spec.notifs)
    local opts = Plugin.values(spec.plugins["nvim-lspconfig"], "opts", false)
    assert.is_false(opts.servers.omnisharp.enable_roslyn_analyzers)
    assert.is_true(opts.servers.omnisharp.enable_import_completion)
    assert.same({}, opts.servers.fsautocomplete)
  end)

  it("optional language integrations do not enable DAP, tests or formatters", function()
    local spec = Plugin.Spec.new({ import = "lazyvim.plugins.extras.lang.dotnet" })
    assert.same({}, spec.notifs)
    for _, name in ipairs({ "nvim-dap", "neotest", "neotest-vstest", "none-ls.nvim", "conform.nvim" }) do
      assert.is_nil(spec.plugins[name], name .. " unexpectedly enabled")
    end
    -- A positive control ensures the optional fragment survives when opted in.
    local enabled = Plugin.Spec.new({
      { "mfussenegger/nvim-dap" },
      { "nvim-neotest/neotest" },
      { import = "lazyvim.plugins.extras.lang.dotnet" },
    })
    assert.same({}, enabled.notifs)
    assert.is_not_nil(enabled.plugins["nvim-dap"].opts)
    assert.is_not_nil(enabled.plugins["neotest-vstest"])
    assert.is_not_nil(Plugin.values(enabled.plugins.neotest, "opts", false).adapters["neotest-vstest"])
  end)
end)
