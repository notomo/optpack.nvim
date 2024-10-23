local M = {}

function M.to_lines(messages)
  return vim
    .iter(messages)
    :map(function(chunks)
      local strs = vim
        .iter(chunks)
        :map(function(chunk)
          return chunk[1]
        end)
        :totable()
      return table.concat(strs, "")
    end)
    :totable()
end

local hl = vim.hl or vim.highlight
local priority = hl.priorities.user - 1
function M.highlight(decorator, messages, row)
  for i, chunks in ipairs(messages) do
    local start_col = 0
    for _, chunk in ipairs(chunks) do
      local text = chunk[1]
      local hl_group = chunk[2]
      local end_col = start_col + #text
      decorator:highlight(hl_group, row + i - 1, start_col, end_col, { priority = priority })
      start_col = end_col
    end
  end
end

return M
