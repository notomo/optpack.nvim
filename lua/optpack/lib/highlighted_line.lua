local M = {}

local HighlightedLines = {}
HighlightedLines.__index = HighlightedLines
M.HighlightedLines = HighlightedLines

local HighlightedLine = {}
HighlightedLine.__index = HighlightedLine

function HighlightedLines.new(raw_hl_lines)
  vim.validate({ raw_hl_lines = { raw_hl_lines, "table" } })
  local tbl = {
    _lines = vim.tbl_map(function(pairs)
      return HighlightedLine.new(pairs)
    end, raw_hl_lines),
  }
  return setmetatable(tbl, HighlightedLines)
end

function HighlightedLines.lines(self)
  return vim.tbl_map(function(line)
    return line:str()
  end, self._lines)
end

function HighlightedLines.add_highlight(self, bufnr, ns, end_row)
  local row = end_row - #self._lines
  for _, line in ipairs(self._lines) do
    line:add_highlight(bufnr, ns, row)
    row = row + 1
  end
end

function HighlightedLine.new(text_hl_pairs)
  local tbl = { _pairs = text_hl_pairs }
  return setmetatable(tbl, HighlightedLine)
end

function HighlightedLine.str(self)
  return table.concat(
    vim.tbl_map(function(pair)
      return pair[1]
    end, self._pairs),
    ""
  )
end

function HighlightedLine.add_highlight(self, bufnr, ns, row)
  local start_col = 0
  local last_index = #self._pairs
  for i, pair in ipairs(self._pairs) do
    local text, hl_group = unpack(pair)
    local opts = { hl_group = hl_group, end_col = 0 }
    if i == last_index then
      opts.end_line = row + 1
    else
      opts.end_col = start_col + vim.fn.strdisplaywidth(text) - 1
    end
    vim.api.nvim_buf_set_extmark(bufnr, ns, row, start_col, opts)
    start_col = opts.end_col + 1
  end
end

return M
