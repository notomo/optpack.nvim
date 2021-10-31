local modulelib = require("optpack.lib.module")

local M = {}

local Outputters = {}
Outputters.__index = Outputters
M.Outputters = Outputters

function Outputters.from(raw_outputters)
  vim.validate({raw_outputters = {raw_outputters, "table"}})

  local outputters = {}
  local errs = {}
  for _, raw_outputter in ipairs(raw_outputters) do
    local outputter, err = Outputters._create_one(raw_outputter.type, raw_outputter.opts)
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

function Outputters._create_one(typ, opts)
  vim.validate({typ = {typ, "string"}, opts = {opts, "table", true}})
  opts = opts or {}
  local Outputter = modulelib.find("optpack.view.outputter." .. typ)
  if not Outputter then
    return nil, "not found outputter: " .. typ
  end
  return Outputter.new(opts)
end

return M
