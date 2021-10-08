local M = {}

local Outputter = {}

function Outputter.new(typ)
  local ok, outputter = pcall(require, "optpack.view.outputter." .. typ)
  if not ok then
    return nil, "not found outputter: " .. typ
  end

  local fields, err = outputter.init()
  if err then
    return nil, err
  end
  local tbl = {_fields = fields, _outputter = outputter}
  return setmetatable(tbl, Outputter)
end

function Outputter.__index(self, k)
  return rawget(Outputter, k) or self._outputter[k] or self._fields[k]
end

local Outputters = {}
Outputters.__index = Outputters
M.Outputters = Outputters

function Outputters.new(outputters, ctx)
  vim.validate({outputters = {outputters, "table"}, ctx = {ctx, "table"}})
  local tbl = {_outputters = outputters, _ctx = ctx}
  return setmetatable(tbl, Outputters)
end

function Outputters.from(types)
  vim.validate({types = {types, "table"}})
  local outputters = {}
  local errs = {}
  for _, typ in ipairs(types) do
    local outputter, err = Outputter.new(typ)
    if err then
      table.insert(errs, err)
    else
      table.insert(outputters, outputter)
    end
  end
  if #errs ~= 0 then
    return nil, table.concat(errs, "\n")
  end

  return Outputters.new(outputters, {})
end

function Outputters.info(self, msg)
  for _, outputter in ipairs(self._outputters) do
    outputter:info(self._ctx, msg)
  end
end

function Outputters.error(self, err)
  for _, outputter in ipairs(self._outputters) do
    outputter:error(self._ctx, err)
  end
end

function Outputters.with(self, ctx)
  ctx = vim.tbl_extend("force", self._ctx, ctx)
  return Outputters.new(self._outputters, ctx)
end

return M
