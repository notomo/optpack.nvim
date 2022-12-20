local M = {}

function M.join(...)
  local items = {}
  local slash = false
  for _, item in ipairs({ ... }) do
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

function M.parent(path)
  if vim.endswith(path, "/") then
    local index = path:reverse():find("/", 2) or 0
    path = path:sub(1, #path - index + 1)
    return path
  end
  local index = path:reverse():find("/") or 0
  path = path:sub(1, #path - index + 1)
  return path
end

function M.tail(path)
  if not vim.endswith(path, "/") then
    local factors = vim.split(path, "/", true)
    return factors[#factors]
  end
  local factors = vim.split(path:sub(1, #path - 1), "/", true)
  return factors[#factors] .. "/"
end

function M.trim_slash(path)
  if not vim.endswith(path, "/") or path == "/" then
    return path
  end
  return path:sub(1, #path - 1)
end

local _normalize
if vim.loop.os_uname().version:match("Windows") then
  _normalize = function(path)
    path = path:gsub("\\", "/")
    return path
  end
else
  _normalize = function(path)
    return path
  end
end
M.normalize = _normalize

return M
