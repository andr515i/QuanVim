-- Configuration disables automatic management. Fail loudly if it is attempted
-- anyway, before lazy.nvim can run install/update/build tasks.
local path = assert(vim.api.nvim_get_runtime_file("lua/lazy/manage/init.lua", false)[1])
package.preload["lazy.manage"] = function()
  local manage = assert(loadfile(path))()
  manage.run = function()
    error("Plugin management is forbidden in offline regression tests")
  end
  return manage
end
