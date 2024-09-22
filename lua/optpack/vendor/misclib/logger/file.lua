local M = {}

function M.output(path_suffix, base_dir_path)
  vim.validate({
    path_suffix = { path_suffix, "string" },
    base_dir_path = { base_dir_path, "string", true },
  })
  local file_path = vim.fs.joinpath(base_dir_path or vim.fn.stdpath("log"), path_suffix)

  local dir_path = vim.fs.dirname(file_path)
  vim.fn.mkdir(dir_path, "p")

  local file = io.open(file_path, "a+")
  if not file then
    error("cannot open file: " .. file_path)
  end
  local output = function(msg)
    file:write(msg)
  end
  return output, file, file_path
end

return M
