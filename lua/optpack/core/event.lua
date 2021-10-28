local M = {}

M.Event = {
  StartInstall = "StartInstall",
  GitCloned = "GitCloned",
  Installed = "Installed",
  FinishedInstall = "FinishedInstall",

  StartUpdate = "StartUpdate",
  GitPulled = "GitPulled",
  Updated = "Updated",
  GitCommitLog = "GitCommitLog",
  FinishedUpdate = "FinishedUpdate",

  Error = "Error",
}

return M
