local M = {}

local join = function(...)
  local items = {}
  local slash = false
  for _, item in ipairs({ ... }) do
    item = vim.fs.normalize(item)
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

function M.output(path_suffix, base_dir_path)
  vim.validate({
    path_suffix = { path_suffix, "string" },
    base_dir_path = { base_dir_path, "string", true },
  })
  local file_path = join(base_dir_path or vim.fn.stdpath("log"), path_suffix)

  local dir_path = vim.fs.dirname(file_path)
  vim.fn.mkdir(dir_path, "p")

  local file = io.open(file_path, "a+")
  local output = function(msg)
    file:write(msg)
  end
  return output, file, file_path
end

return M
