local modulelib = require("optpack.vendor.misclib.module")

local Outputters = {}
Outputters.__index = Outputters

--- @param cmd_type string
--- @param raw_outputters table
function Outputters.new(cmd_type, raw_outputters)
  local outputters = {}
  local errs = {}
  vim.iter(raw_outputters):each(function(outputter_typ, outputter_opts)
    if not outputter_opts.enabled then
      return
    end

    local outputter = Outputters._new_one(cmd_type, outputter_typ, outputter_opts)
    if type(outputter) == "string" then
      local err = outputter
      table.insert(errs, err)
      return
    end

    table.insert(outputters, outputter)
  end)
  if #errs ~= 0 then
    return table.concat(errs, "\n")
  end

  return outputters
end

--- @param cmd_type string
--- @param typ string
--- @param outputter_opts table?
function Outputters._new_one(cmd_type, typ, outputter_opts)
  outputter_opts = outputter_opts or {}
  local Outputter = modulelib.find("optpack.view.outputter." .. typ)
  if not Outputter then
    return "not found outputter: " .. typ
  end
  return Outputter.new(cmd_type, outputter_opts)
end

return Outputters
