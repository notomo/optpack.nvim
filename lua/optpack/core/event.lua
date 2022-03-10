local M = {}

M.Event = {
  StartInstall = "StartInstall",
  Installed = "Installed",
  FinishedInstall = "FinishedInstall",

  StartUpdate = "StartUpdate",
  Updated = "Updated",
  GitCommitLog = "GitCommitLog",
  FinishedUpdate = "FinishedUpdate",

  Progressed = "Progressed",

  Error = "Error",
}

local Specific = {
  install = {
    Start = M.Event.StartInstall,
    Finished = M.Event.FinishedInstall,
  },
  update = {
    Start = M.Event.StartUpdate,
    Finished = M.Event.FinishedUpdate,
  },
}

function M.specific(cmd_type)
  return vim.tbl_extend("force", M.Event, Specific[cmd_type])
end

return M
