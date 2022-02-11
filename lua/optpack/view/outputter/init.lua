local modulelib = require("optpack.lib.module")

local Outputters = {}
Outputters.__index = Outputters

function Outputters.new(cmd_type, raw_outputters)
  vim.validate({ raw_outputters = { raw_outputters, "table" } })

  local outputters = {}
  local errs = {}
  for outputter_typ, outputter_opts in pairs(raw_outputters) do
    local outputter, err = Outputters._new_one(cmd_type, outputter_typ, outputter_opts)
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

function Outputters._new_one(cmd_type, typ, outputter_opts)
  vim.validate({
    cmd_type = { cmd_type, "string" },
    typ = { typ, "string" },
    outputter_opts = { outputter_opts, "table", true },
  })
  outputter_opts = outputter_opts or {}
  local Outputter = modulelib.find("optpack.view.outputter." .. typ)
  if not Outputter then
    return nil, "not found outputter: " .. typ
  end
  return Outputter.new(cmd_type, outputter_opts)
end

return Outputters
