local M = {}

local Git = {}
Git.__index = Git
M.Git = Git

function Git.new()
  local tbl = {cloned = {}, pulled = {}}
  return setmetatable(tbl, Git)
end

function Git.clone(self, directory, url, depth)
  table.insert(self.cloned, {url = url, directory = directory, depth = depth})
end

function Git.pull(self, directory)
  table.insert(self.pulled, {directory = directory})
end

return M
