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
  fetch = {depth = 1, base_url = "https://github.com"},
  package_name = "optpack",
  select_packpath = function()
    return vim.opt.packpath:get()[1]
  end,
  enabled = true,
}

function Option.new(raw_opts)
  vim.validate({raw_opts = {raw_opts, "table", true}})
  raw_opts = raw_opts or {}
  return vim.tbl_deep_extend("force", Option.default, raw_opts)
end

local UpdateOption = {}
UpdateOption.__index = UpdateOption
M.UpdateOption = UpdateOption

UpdateOption.default = {
  on_finished = function()
  end,
  pattern = ".*",
  outputters = {
    {
      type = "buffer",
      opts = {
        open = function(bufnr)
          vim.cmd("botright split | buffer" .. bufnr)
        end,
      },
    },
  },
  parallel_limit = 8,
  parallel_interval = 250,
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
