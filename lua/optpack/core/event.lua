local M = {}

M.Event = {
  StartInstall = "StartInstall",
  GitCloned = "GitCloned",
  Installed = "Installed",
  FinishedInstall = "FinishedInstall",

  StartUpdate = "StartUpdate",
  GitPulled = "GitPulled",
  Updated = "Updated",
  FinishedUpdate = "FinishedUpdate",

  Error = "Error",
}

return M
