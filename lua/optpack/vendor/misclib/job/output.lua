local Output = {}
Output.__index = Output

function Output.new()
  local tbl = { _lines = { "" } }
  return setmetatable(tbl, Output)
end

function Output.collector(self)
  return function(_, data)
    self._lines[#self._lines] = self._lines[#self._lines] .. data[1]
    vim.list_extend(self._lines, vim.list_slice(data, 2))
  end
end

function Output.lines(self)
  if self._lines[#self._lines] ~= "" then
    return vim.list_slice(self._lines, 1, #self._lines)
  end
  return vim.list_slice(self._lines, 1, #self._lines - 1)
end

function Output.str(self)
  return table.concat(self:lines(), "\n")
end

local OutputBuffer = {}
OutputBuffer.__index = OutputBuffer

function Output.new_buffer()
  local tbl = { _lines = { "" } }
  return setmetatable(tbl, OutputBuffer)
end

function OutputBuffer.append(self, data)
  self._lines[#self._lines] = self._lines[#self._lines] .. data[1]
  vim.list_extend(self._lines, vim.list_slice(data, 2))
  local completed = table.concat(vim.list_slice(self._lines, 1, #self._lines - 1), "\n")
  self._lines = { self._lines[#self._lines] }
  return completed
end

function OutputBuffer.pop(self)
  return self:append({ "", "" })
end

return Output
