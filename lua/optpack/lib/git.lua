local M = {}

local Git = {}
Git.__index = Git
M.Git = Git

function Git.new()
  local tbl = {}
  return setmetatable(tbl, Git)
end

function Git.clone(self, directory, url, depth)
  -- TODO
end

function Git.pull(self, directory)
  -- TODO
end

return M
