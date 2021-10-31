local modulelib = require("optpack.lib.module")

local M = {}

local Outputters = {}
Outputters.__index = Outputters
M.Outputters = Outputters

function Outputters.from(cmd_type, raw_outputters)
  vim.validate({raw_outputters = {raw_outputters, "table"}})

  local outputters = {}
  local errs = {}
  for _, raw_outputter in ipairs(raw_outputters) do
    local outputter, err = Outputters._create_one(cmd_type, raw_outputter.type, raw_outputter.opts)
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

function Outputters._create_one(cmd_type, typ, opts)
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
  return Outputter.new(cmd_type, opts)
end

return M
