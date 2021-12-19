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

return M
