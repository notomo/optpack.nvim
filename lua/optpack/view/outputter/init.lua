local modulelib = require("optpack.lib.module")

local M = {}

local Outputters = {}
Outputters.__index = Outputters
M.Outputters = Outputters

function Outputters.from(types)
  vim.validate({types = {types, "table"}})

  local outputters = {}
  local errs = {}
  for _, typ in ipairs(types) do
    local outputter, err = Outputters._create_one(typ)
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

function Outputters._create_one(typ)
  local Outputter = modulelib.find("optpack.view.outputter." .. typ)
  if not Outputter then
    return nil, "not found outputter: " .. typ
  end
  return Outputter.new()
end

return M
