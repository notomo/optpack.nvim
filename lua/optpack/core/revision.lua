local Promise = require("optpack.lib.promise")

local M = {}

local RevisionType = {branch = "branch", commit = "commit", tag = "tag"}
local revision_setter = {
  [RevisionType.branch] = function(tbl, raw_revision)
    tbl._branch = raw_revision
    tbl.checkoutable = "origin/" .. tbl._branch
  end,
  [RevisionType.commit] = function(tbl, raw_revision)
    tbl._commit = raw_revision
    tbl.checkoutable = tbl._commit
  end,
  [RevisionType.tag] = function(tbl, raw_revision)
    tbl._tag = "refs/tags/" .. raw_revision
    tbl.checkoutable = "origin/" .. tbl._tag
  end,
}

local Revision = {}
Revision.__index = Revision
M.Revision = Revision

function Revision.new(raw_revision, typ)
  vim.validate({raw_revision = {raw_revision, "string"}, typ = {typ, "string"}})
  if not RevisionType[typ] then
    return nil, "not found revision_type: " .. typ
  end
  local tbl = {}
  revision_setter[typ](tbl, raw_revision)
  return setmetatable(tbl, Revision)
end

function Revision.is_default(self)
  return self._branch == ""
end

local RevisionSwitcher = {}
RevisionSwitcher.__index = RevisionSwitcher
M.RevisionSwitcher = RevisionSwitcher

function RevisionSwitcher.new(git, directory, revision)
  vim.validate({
    git = {git, "table"},
    directory = {directory, "string"},
    revision = {revision, "table"},
  })
  local tbl = {_git = git, _directory = directory, _revision = revision}
  return setmetatable(tbl, RevisionSwitcher)
end

function RevisionSwitcher.start(self)
  if self._revision:is_default() then
    return Promise.resolve(false)
  end

  -- TODO fetch origin
  local setting_revision
  return self._git:get_revision(self._directory, self._revision.checkoutable):next(function(raw_revision)
    setting_revision = raw_revision
    return self._git:get_revision(self._directory)
  end):next(function(current_revision)
    if setting_revision == current_revision then
      return false
    end
    return self._git:checkout(self._directory, self._revision.checkoutable)
  end)
end

return M
