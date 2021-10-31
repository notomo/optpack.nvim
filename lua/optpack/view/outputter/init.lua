local modulelib = require("optpack.lib.module")

local M = {}

local Outputters = {}
Outputters.__index = Outputters
M.Outputters = Outputters

function Outputters.from(outputs)
  vim.validate({outputs = {outputs, "table"}})

  local outputters = {}
  local errs = {}
  for _, output in ipairs(outputs) do
    local outputter, err = Outputters._create_one(output.type, output.opts)
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
