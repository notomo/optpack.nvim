local M = {}
M.__index = M

function M.setup(root_path, opts)
  opts = opts or {}
  -- Suffix the base dir with the pid so concurrent test processes never share a
  -- parent directory and therefore never race to create one via `mkdir -p`
  -- (each fresh process otherwise produces the same unseeded math.random
  -- sequence). e.g. "test_data/" -> "test_data_42/".
  local base_dir = ("%s_%d"):format((opts.base_dir or "test_data"):gsub("/+$", ""), vim.fn.getpid())
  local relative_path = vim.fs.joinpath(base_dir, tostring(math.random(1, 2 ^ 30)))
  local full_path = vim.fs.joinpath(root_path, relative_path)
  local tbl = {
    full_path = full_path,
    _relative_path = relative_path,
    _base_path = vim.fs.joinpath(root_path, base_dir),
    _original_cwd = vim.fn.getcwd(),
  }
  local self = setmetatable(tbl, M)

  self:create_dir("")

  return self
end

function M.create_file(self, path, content)
  self:create_dir(vim.fs.dirname(path))

  local file_path = vim.fs.joinpath(self.full_path, path)
  local f = io.open(file_path, "w")
  if not f then
    error("cannot open: " .. file_path)
  end
  if content then
    f:write(content)
  end
  f:close()

  return file_path
end

function M.create_dir(self, path)
  local dir_path = vim.fs.joinpath(self.full_path, path)
  vim.fn.mkdir(dir_path, "p")
  return dir_path
end

function M.path(self, path)
  return vim.fs.joinpath(self.full_path, path)
end

function M.relative_path(self, path)
  return vim.fs.joinpath(self._relative_path, path)
end

function M.cd(self, path)
  local dir_path = vim.fs.joinpath(self.full_path, path)
  vim.api.nvim_set_current_dir(dir_path)
end

local delete = function(target_path)
  local result = vim.fn.delete(target_path, "rf")
  if result == -1 or result == true then
    error("failed to delete: " .. target_path)
  end
end

function M.delete(self, path)
  local target_path = vim.fs.joinpath(self.full_path, path)
  delete(target_path)
end

function M.teardown(self)
  -- A spec may `cd` into the data dir; on Windows a directory cannot be deleted
  -- while it is the cwd, so restore the original cwd before deleting. The base
  -- dir is per-process (pid-suffixed) and specs within a process run serially,
  -- so deleting it whole is safe and leaves no empty residue behind.
  vim.api.nvim_set_current_dir(self._original_cwd)
  delete(self._base_path)
end

return M
