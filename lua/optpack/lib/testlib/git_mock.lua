local M = {}

local Git = {}
Git.__index = Git
M.Git = Git

function Git.new()
  local tbl = {cloned = {}, pulled = {}}
  return setmetatable(tbl, Git)
end

function Git.clone(self, outputters, directory, url, depth)
  local ctx = {event_name = "clone", url = url, directory = directory, depth = depth}
  table.insert(self.cloned, ctx)
  outputters:info("ok")
end

function Git.pull(self, outputters, directory)
  local ctx = {event_name = "pull", directory = directory}
  table.insert(self.pulled, ctx)
  outputters:info("ok")
end

return M
