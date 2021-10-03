local M = {}

local Hooks = {}
Hooks.__index = Hooks
M.Hooks = Hooks

Hooks.default = {
  pre_load = function()
  end,
  post_load = function()
  end,
}

function Hooks.new(raw_hooks)
  vim.validate({raw_hooks = {raw_hooks, "table", true}})
  raw_hooks = raw_hooks or {}
  return vim.tbl_deep_extend("force", Hooks.default, raw_hooks)
end

return M
