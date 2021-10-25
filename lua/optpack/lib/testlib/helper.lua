local plugin_name = vim.split((...):gsub("%.", "/"), "/", true)[1]
local M = require("vusted.helper")

M.root = M.find_plugin_root(plugin_name)
M.runtimepath = vim.o.runtimepath
M.packpath = vim.o.packpath

function M.before_each()
  vim.o.packpath = M.packpath
  vim.o.runtimepath = M.runtimepath
  vim.cmd("filetype on")
  vim.cmd("syntax enable")
  M.test_data_path = "spec/test_data/" .. math.random(1, 2 ^ 30) .. "/"
  M.test_data_dir = M.root .. "/" .. M.test_data_path
  M.new_directory("")
end

function M.after_each()
  vim.cmd("tabedit")
  vim.cmd("tabonly!")
  vim.cmd("silent %bwipeout!")
  M.cleanup_loaded_modules(plugin_name)
  vim.fn.delete(M.root .. "/spec/test_data", "rf")
  vim.cmd("comclear")
  vim.cmd("silent! autocmd! optpack")
  print(" ")
end

function M.new_file(path, ...)
  local f = io.open(M.test_data_dir .. path, "w")
  for _, line in ipairs({...}) do
    f:write(line .. "\n")
  end
  f:close()
end

function M.new_directory(path)
  vim.fn.mkdir(M.test_data_dir .. path, "p")
end

function M.delete(path)
  vim.fn.delete(M.test_data_dir .. path, "rf")
end

function M.git_server()
  local cgi_root_dir = M.root .. "/spec/lua/optpack"
  local git_root_dir = M.root .. "/spec/lua/optpack/git"
  local tmp_dir = M.root .. "/spec/lua/optpack/tmp"
  return require("optpack.lib.testlib.git_server").GitServer.new(cgi_root_dir, git_root_dir, tmp_dir)
end

function M.print_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  print(table.concat(lines, "\n"))
end

function M.on_finished()
  local finished = false
  return setmetatable({
    wait = function()
      local ok = vim.wait(1000, function()
        return finished
      end, 10, false)
      if not ok then
        error("wait timeout")
      end
    end,
  }, {
    __call = function()
      finished = true
    end,
  })
end

local asserts = require("vusted.assert").asserts

asserts.create("length"):register_eq(function(tbl)
  return #tbl
end)

asserts.create("window_count"):register_eq(function()
  return vim.fn.tabpagewinnr(vim.fn.tabpagenr(), "$")
end)

asserts.create("exists_message"):register(function(self)
  return function(_, args)
    local expected = args[1]
    self:set_positive(("`%s` not found message"):format(expected))
    self:set_negative(("`%s` found message"):format(expected))
    local messages = vim.split(vim.api.nvim_exec("messages", true), "\n")
    for _, msg in ipairs(messages) do
      if msg:match(expected) then
        return true
      end
    end
    return false
  end
end)

asserts.create("exists_dir"):register(function(self)
  return function(_, args)
    local path = M.test_data_dir .. args[1]
    self:set_positive(("`%s` not found dir"):format(path))
    self:set_negative(("`%s` found dir"):format(path))
    return vim.fn.isdirectory(path) == 1
  end
end)

asserts.create("exists_pattern"):register(function(self)
  return function(_, args)
    local pattern = args[1]
    pattern = pattern:gsub("\n", "\\n")
    local result = vim.fn.search(pattern, "n")
    self:set_positive(("`%s` not found"):format(pattern))
    self:set_negative(("`%s` found"):format(pattern))
    return result ~= 0
  end
end)

return M
