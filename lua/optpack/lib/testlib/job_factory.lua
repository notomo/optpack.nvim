local JobFactory = require("optpack.lib.job_factory").JobFactory

local M = {}

local TestJobFactory = {}
TestJobFactory.__index = TestJobFactory
M.TestJobFactory = TestJobFactory

function TestJobFactory.new(cmd_handler, opts_handler)
  vim.validate({cmd_handler = {cmd_handler, "function"}, opts_handler = {opts_handler, "function"}})
  local tbl = {_cmd_handler = cmd_handler, _opts_handler = opts_handler}
  return setmetatable(tbl, TestJobFactory)
end

function TestJobFactory.create(self, cmd, opts)
  return JobFactory.new():create(self._cmd_handler(cmd), self._opts_handler(opts))
end

return M
