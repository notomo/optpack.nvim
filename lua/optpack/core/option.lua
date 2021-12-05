local Event = require("optpack.core.event").Event

local M = {}

M.user_default = {add = {}, install_or_update = {}}
function M.set_default(setting)
  M.user_default = vim.tbl_deep_extend("force", M.user_default, setting)
end

local AddOption = {}
AddOption.__index = AddOption
M.AddOption = AddOption

AddOption.default = {
  load_on = {events = {}, modules = {}, cmds = {}, filetypes = {}},
  hooks = {
    post_add = function()
    end,
    pre_load = function()
    end,
    post_load = function()
    end,
    post_install = function()
    end,
    post_update = function()
    end,
  },
  fetch = {depth = 1, base_url = "https://github.com", revision = "", revision_type = "branch"},
  package_name = "optpack",
  select_packpath = function()
    return vim.opt.packpath:get()[1]
  end,
  enabled = true,
}

function AddOption.new(raw_opts)
  vim.validate({raw_opts = {raw_opts, "table", true}})
  raw_opts = raw_opts or {}
  return vim.tbl_deep_extend("force", AddOption.default, M.user_default.add, raw_opts)
end

local InstallOrUpdateOption = {}
InstallOrUpdateOption.__index = InstallOrUpdateOption
M.InstallOrUpdateOption = InstallOrUpdateOption

InstallOrUpdateOption.default = {
  on_finished = function()
  end,
  pattern = ".*",
  outputters = {
    {
      type = "buffer",
      handlers = {
        [Event.Progressed] = function(_, _, finished_count, all_count)
          local digit = #tostring(all_count)
          local fmt = ("[ %%%dd / %%%dd ]"):format(digit, digit)
          return nil, {{{(fmt):format(finished_count, all_count), "OptpackProgressed"}}}
        end,
      },
      opts = {
        open = function(bufnr)
          vim.cmd("botright split | buffer" .. bufnr)
        end,
      },
    },
  },
  parallel = {limit = 8},
}

function InstallOrUpdateOption.new(raw_opts)
  vim.validate({raw_opts = {raw_opts, "table", true}})
  raw_opts = raw_opts or {}
  local opts = vim.tbl_deep_extend("force", InstallOrUpdateOption.default, M.user_default.install_or_update, raw_opts)
  local ok, err = pcall(vim.regex, opts.pattern)
  if not ok then
    return nil, ([[invalid pattern `%s`: %s]]):format(opts.pattern, err)
  end
  return opts, nil
end

return M
