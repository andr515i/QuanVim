describe("Startup regression", function()
  for _, scenario in ipairs({ "empty", "lua", "old", "explicit", "missing" }) do
    it(scenario, function()
      local root = vim.env.QUANVIM_TEST_ROOT .. "/" .. scenario
      local config = root .. "/config/nvim"
      vim.fn.mkdir(config, "p")
      vim.fn.system({ "cp", "-R", "tests/startup/consumer/.", config })
      assert.are.equal(0, vim.v.shell_error)
      local env = {
        HOME = root .. "/home",
        XDG_CONFIG_HOME = root .. "/config",
        XDG_DATA_HOME = root .. "/data",
        XDG_STATE_HOME = root .. "/state",
        XDG_CACHE_HOME = root .. "/cache",
        QUANVIM_TEST_SCENARIO = scenario,
        QUANVIM_TEST_REPO = vim.uv.cwd(),
      }
      local command = { vim.v.progpath, "--headless", "-i", "NONE", "-u", config .. "/init.lua" }
      if scenario == "lua" then
        vim.fn.writefile({ "local example = true" }, root .. "/example.lua")
        command[#command + 1] = root .. "/example.lua"
      end
      local result = vim.system(command, { env = env, text = true, timeout = 15000 }):wait()
      assert.are.equal(0, result.code, result.stdout .. result.stderr)
      assert.is_true(result.stdout:find("STARTUP OK " .. scenario, 1, true) ~= nil, result.stdout .. result.stderr)
      assert.are.equal("", result.stderr)
    end)
  end
end)
