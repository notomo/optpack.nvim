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
  -- TODO: base_url to format_url()?
  fetch = {engine = "git", depth = 1, base_url = "https://github.com/"},
  package_name = "optpack",
  enabled = true,
}

function Option.new(raw_opts)
  vim.validate({raw_opts = {raw_opts, "table", true}})
  raw_opts = raw_opts or {}
  local opts = vim.tbl_deep_extend("force", Option.default, raw_opts)

  if type(opts.fetch.engine) == "string" then
    opts.fetch.engine = require("optpack.lib.git").Git.new()
  end
  vim.validate({["opts.fetch.engine"] = {opts.fetch.engine, "table"}})

  return opts
end

local UpdateOption = {}
UpdateOption.__index = UpdateOption
M.UpdateOption = UpdateOption

UpdateOption.default = {
  on_finished = function()
  end,
  pattern = ".*",
  output_types = {"buffer"},
  parallel_limit = 8,
}

function UpdateOption.new(raw_opts)
  vim.validate({raw_opts = {raw_opts, "table", true}})
  raw_opts = raw_opts or {}
  return vim.tbl_deep_extend("force", UpdateOption.default, raw_opts)
end

local InstallOption = {}
InstallOption.__index = InstallOption
M.InstallOption = InstallOption

InstallOption.default = vim.deepcopy(UpdateOption.default)

function InstallOption.new(raw_opts)
  vim.validate({raw_opts = {raw_opts, "table", true}})
  raw_opts = raw_opts or {}
  return vim.tbl_deep_extend("force", InstallOption.default, raw_opts)
end

return M
