local MessageFactory = require("optpack.view.message_factory").MessageFactory
local modulelib = require("optpack.lib.module")

local M = {}

local Outputters = {}
Outputters.__index = Outputters
M.Outputters = Outputters

function Outputters.new(cmd_type, raw_outputters)
  vim.validate({raw_outputters = {raw_outputters, "table"}})

  local outputters = {}
  local errs = {}
  for _, raw_outputter in ipairs(raw_outputters) do
    local outputter, err = Outputters._new_one(cmd_type, raw_outputter.type, raw_outputter.handlers, raw_outputter.opts)
    if err then
      table.insert(errs, err)
    else
      table.insert(outputters, outputter)
    end
  end
  if #errs ~= 0 then
    return nil, table.concat(errs, "\n")
  end
  return outputters
end

function Outputters._new_one(cmd_type, typ, handlers, opts)
  vim.validate({
    cmd_type = {cmd_type, "string"},
    typ = {typ, "string"},
    opts = {opts, "table", true},
  })
  opts = opts or {}
  local Outputter = modulelib.find("optpack.view.outputter." .. typ)
  if not Outputter then
    return nil, "not found outputter: " .. typ
  end
  local message_factory = MessageFactory.new(handlers)
  return Outputter.new(cmd_type, message_factory, opts)
end

return M
