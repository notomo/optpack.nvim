local helper = require("vusted.helper")
local plugin_name = helper.get_module_root(...)

helper.root = helper.find_plugin_root(plugin_name)
helper.runtimepath = vim.o.runtimepath

function helper.before_each()
  vim.o.runtimepath = helper.runtimepath
  helper.test_data = require("optpack.vendor.misclib.test.data_dir").setup(helper.root)
end

function helper.after_each()
  helper.cleanup()
  helper.cleanup_loaded_modules(plugin_name)
  helper.test_data:teardown()
  collectgarbage("collect") -- for unhandled rejection
  print(" ")
end

function helper.set_lines(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(lines, "\n"))
end

function helper.git_server()
  local cgi_root_dir = helper.root .. "/spec/lua/optpack"
  local git_root_dir = helper.root .. "/spec/lua/optpack/git"
  local tmp_dir = helper.root .. "/spec/lua/optpack/tmp"
  return require("optpack.test.git_server").new(cgi_root_dir, git_root_dir, tmp_dir)
end

function helper.print_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  print(table.concat(lines, "\n"))
end

function helper.on_finished()
  local finished = false
  return setmetatable({
    wait = function()
      local ok = vim.wait(1000, function()
        return finished
      end, 10, false)
      if not ok then
        helper.print_buffer()
        error("wait timeout")
      end
    end,
  }, {
    __call = function()
      finished = true
    end,
  })
end

helper.packpath_name = "mypackpath"
helper.opt_path = helper.packpath_name .. "/pack/optpack/opt/"

function helper.plugin_dir(name)
  return helper.test_data.full_path .. helper.opt_path .. name
end

function helper.create_plugin_dir(name, opts)
  opts = opts or {}
  helper.cleanup_loaded_modules(name)

  opts.opt_path = opts.opt_path or helper.opt_path
  local root_dir = opts.opt_path .. name

  local plugin_dir = ("%s/plugin/"):format(root_dir)
  opts.plugin_vim_content = opts.plugin_vim_content or ""
  helper.test_data:create_file(plugin_dir .. name .. ".vim", opts.plugin_vim_content)

  local lua_dir = ("%s/lua/%s/"):format(root_dir, name)
  helper.test_data:create_file(lua_dir .. "init.lua")
  helper.test_data:create_file(lua_dir .. "sub/init.lua")
end

function helper.set_packpath()
  vim.o.packpath = helper.test_data.full_path .. helper.packpath_name
end

local asserts = require("vusted.assert").asserts
local asserters = require(plugin_name .. ".vendor.assertlib").list()
require(plugin_name .. ".vendor.misclib.test.assert").register(asserts.create, asserters)

asserts.create("exists_dir"):register(function(self)
  return function(_, args)
    local path = helper.test_data.full_path .. args[1]
    self:set_positive(("`%s` not found dir"):format(path))
    self:set_negative(("`%s` found dir"):format(path))
    return vim.fn.isdirectory(path) == 1
  end
end)

asserts.create("can_require"):register(function(self)
  return function(_, args)
    local path = args[1]
    local ok, result = pcall(require, path)
    self:set_positive(("cannot require `%s`: %s"):format(path, result))
    self:set_negative(("can require `%s`"):format(path))
    return ok
  end
end)

return helper
