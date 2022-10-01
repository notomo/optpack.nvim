local M = {}

function M.to_lines(messages)
  return vim.tbl_map(function(chunks)
    local strs = vim.tbl_map(function(chunk)
      return chunk[1]
    end, chunks)
    return table.concat(strs, "")
  end, messages)
end

function M.highlight(decorator, messages, row)
  for _, chunks in ipairs(messages) do
    local start_col = 0
    for _, chunk in ipairs(chunks) do
      local text = chunk[1]
      local hl_group = chunk[2]
      local end_col = start_col + #text
      decorator:highlight(hl_group, row, start_col, end_col)
      start_col = end_col
    end
  end
end

return M
