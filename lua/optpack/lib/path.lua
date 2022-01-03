local M = {}

function M.join(...)
  local items = {}
  local slash = false
  for _, item in ipairs({ ... }) do
    item = M.adjust_sep(item)
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
  path = M.adjust_sep(path)
  if vim.endswith(path, "/") then
    path = path:sub(1, #path - 1)
  end
  local splitted = vim.split(path, "/", true)
  return splitted[#splitted]
end

function M.dir(path)
  path = M.adjust_sep(path)
  if vim.endswith(path, "/") then
    return path
  end
  return vim.fn.fnamemodify(path, ":h")
end

if vim.fn.has("win32") == 1 then
  function M.adjust_sep(path)
    path = path:gsub("\\", "/")
    return path
  end
else
  function M.adjust_sep(path)
    return path
  end
end

return M
