local M = {}

local Option = {}
Option.__index = Option
M.Option = Option

Option.default = {
  load_on = {events = {}, modules = {}, cmds = {}, filetypes = {}},
  hooks = {
    post_add = function()
    end,
    pre_load = function()
    end,
    post_load = function()
    end,
  },
  enabled = true,
}

function Option.new(raw_opts)
  vim.validate({raw_opts = {raw_opts, "table", true}})
  raw_opts = raw_opts or {}
  return vim.tbl_deep_extend("force", Option.default, raw_opts)
end

return M
