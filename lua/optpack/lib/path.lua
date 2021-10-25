local M = {}

function M.join(...)
  local items = {}
  local slash = false
  for _, item in ipairs({...}) do
    if vim.endswith(item, "/") then
      item = item:sub(1, #item - 1)
      slash = true
    else
      slash = false
    end
    table.insert(items, item)
  end
  local path = table.concat(items, "/")
  if slash then
    path = path .. "/"
  end
  return path
end

function M.tail(path)
  local splitted = vim.split(path, "/", true)
  return splitted[#splitted]
end

return M
