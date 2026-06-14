local helper = require("ntf.helper")
local plugin_name = helper.get_module_root(...)

helper.root = helper.find_plugin_root(plugin_name)
vim.opt.packpath:prepend(vim.fs.joinpath(helper.root, "spec/.shared/packages"))
require("assertlib").register(require("ntf.assert").register)

helper.runtimepath = vim.o.runtimepath

function helper.before_each()
  vim.o.runtimepath = helper.runtimepath
  helper.test_data = require("optpack.vendor.misclib.test.data_dir").setup(
    helper.root,
    { base_dir = ("test_data_%d/"):format(vim.fn.getpid()) }
  )
end

function helper.after_each()
  helper.test_data:teardown()
  collectgarbage("collect") -- for unhandled rejection
end

function helper.set_lines(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(lines, "\n"))
end

function helper.git_server()
  local cgi_root_dir = vim.fs.joinpath(helper.root, "/spec/lua/optpack")
  -- Per-process dirs (under nvim's tempdir, auto-cleaned) so parallel workers
  -- don't share git fixtures or cross-delete each other on teardown.
  local base = vim.fn.tempname()
  local git_root_dir = vim.fs.joinpath(base, "git")
  local tmp_dir = vim.fs.joinpath(base, "tmp")
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
helper.opt_path = vim.fs.joinpath(helper.packpath_name, "/pack/optpack/opt/")

function helper.plugin_dir(name)
  return helper.test_data:path(vim.fs.joinpath(helper.opt_path, name))
end

-- Drop the fixture plugin's loaded modules so a later require reloads it.
function helper.cleanup_loaded_modules(module_name)
  local dir = module_name:gsub("/", ".") .. "."
  for key in pairs(package.loaded) do
    if vim.startswith(key:gsub("/", "."), dir) or key == module_name then
      package.loaded[key] = nil
    end
  end
end

function helper.create_plugin_dir(name, opts)
  opts = opts or {}
  helper.cleanup_loaded_modules(name)

  opts.opt_path = opts.opt_path or helper.opt_path
  local root_dir = vim.fs.joinpath(opts.opt_path, name)

  local plugin_dir = ("%s/plugin/"):format(root_dir)
  opts.plugin_vim_content = opts.plugin_vim_content or ""
  helper.test_data:create_file(vim.fs.joinpath(plugin_dir, name .. ".vim"), opts.plugin_vim_content)

  local lua_dir = ("%s/lua/%s/"):format(root_dir, name)
  helper.test_data:create_file(vim.fs.joinpath(lua_dir, "init.lua"))
  helper.test_data:create_file(vim.fs.joinpath(lua_dir, "sub/init.lua"))
end

function helper.set_packpath()
  vim.o.packpath = helper.test_data:path(helper.packpath_name)
end

local assert = require("ntf.assert")

assert.register("exists_dir", function(self)
  return function(_, args)
    local path = helper.test_data:path(args[1])
    self:set_positive(("`%s` not found dir"):format(path))
    self:set_negative(("`%s` found dir"):format(path))
    return vim.fn.isdirectory(path) == 1
  end
end)

assert.register("can_require", function(self)
  return function(_, args)
    local path = args[1]
    local ok, result = pcall(require, path)
    self:set_positive(("cannot require `%s`: %s"):format(path, result))
    self:set_negative(("can require `%s`"):format(path))
    return ok
  end
end)

function helper.typed_assert(raw_assert)
  local x = require("assertlib").typed(raw_assert)
  ---@cast x +{exists_dir:fun(path),can_require:fun(want)}
  ---@cast x +{no:{exists_dir:fun(path),can_require:fun(want)}}
  return x
end

return helper
