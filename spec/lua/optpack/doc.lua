local util = require("genvdoc.util")
local plugin_name = vim.env.PLUGIN_NAME
local full_plugin_name = plugin_name .. ".nvim"

local example_path = ("./spec/lua/%s/example.lua"):format(plugin_name)

vim.o.runtimepath = vim.fn.getcwd() .. "," .. vim.o.runtimepath
dofile(example_path)

require("genvdoc").generate(full_plugin_name, {
  sources = { { name = "lua", pattern = ("lua/%s/init.lua"):format(plugin_name) } },
  chapters = {
    {
      name = function(group)
        return "Lua module: " .. group
      end,
      group = function(node)
        if not node.declaration then
          return nil
        end
        return node.declaration.module
      end,
    },
    {
      name = "TYPES",
      body = function(ctx)
        local add_option_text
        do
          local descriptions = {
            enabled = [[(boolean | nil): if enabled=false, optpack ignores the plugin.
    default: %s]],
            fetch = {
              text = [[(table | nil): fetch setting]],
              children = {
                depth = [[for shallow clone depth. Used full clone if depth < 1.
    default: %s]],
                base_url = [[A git server base url,
    default: %s]],
              },
            },
            hooks = {
              text = [[(table | nil): hook functions for some timings]],
              children = {
                post_add = [[(function | nil) called on after |optpack.add()|]],
                pre_load = [[(function | nil) called on before loading]],
                post_load = [[(function | nil) called on after loading]],
                post_install = [[(function | nil) called on after installing]],
                post_update = [[(function | nil) called on after updating]],
              },
            },
            load_on = {
              text = [[(table | nil): setting for lazy loading]],
              children = {
                events = [[(table | nil): autocmd event name or [name, pattern] list,
    default: %s]],
                modules = [[(table | nil): for require() lua module name list,
    default: %s]],
                cmds = [[(table | nil): EX command pattern list,
    default: %s]],
                filetypes = [[(table | nil): file type pattern list,
    default: %s]],
              },
            },
            package_name = [[(string | nil): used as the package directory name.
    your-packpath/pack/{package_name}/opt
    default: %s]],
            select_packpath = [[(function | nil): returns a directory path.
    default: returns the first element of 'packpath']],
          }
          local default = require("optpack.core.option").AddOption.default
          local keys = vim.tbl_keys(default)
          local lines = util.each_keys_description(keys, descriptions, default)
          add_option_text = table.concat(lines, "\n")
        end

        local install_or_update_option_text
        do
          local descriptions = {
            on_finished = [[(function | nil): called on finished updating or installing]],
            outputters = {
              text = [[(table | nil): outputter settings]],
              children = {
                buffer = {
                  text = [[(table | nil): buffer output setting]],
                  children = { open = [[(function | nil) (bufnr) -> open buffer]] },
                },
              },
            },
            parallel = {
              text = [[(table | nil): parallel setting]],
              children = { limit = [[max number for parallel job,  default: %s]] },
            },
            pattern = [[(string | nil): target plugin name pattern for vim regex,
    default: %s]],
          }
          local default = require("optpack.core.option").InstallOrUpdateOption.default
          local keys = vim.tbl_keys(default)
          local lines = util.each_keys_description(keys, descriptions, default)
          install_or_update_option_text = table.concat(lines, "\n")
        end

        local plugin_text
        do
          local descriptions = {
            directory = [[(string): full path of the plugin directory]],
            full_name = [[(string): {account_name}/{plugin_name} format plugin name]],
            name = [[(string): plugin name]],
            url = [[(string): git repository url]],
          }
          local default = require("optpack.core.plugin").Plugin.new(
            "doc",
            require("optpack.core.option").AddOption.new()
          ):expose()
          local keys = vim.tbl_keys(default)
          local lines = util.each_keys_description(keys, descriptions)
          plugin_text = table.concat(lines, "\n")
        end

        local setting_text
        do
          local descriptions = {
            add = [[(table | nil): |optpack.nvim-add-option|
    default: %s]],
            install_or_update = [[(table | nil): |optpack.nvim-install-or-update-option|
    default: %s]],
          }
          local default = require("optpack.core.option").user_default
          local keys = vim.tbl_keys(default)
          local lines = util.each_keys_description(keys, descriptions, default)
          setting_text = table.concat(lines, "\n")
        end

        return util.sections(ctx, {
          { name = "|optpack.add()| option", tag_name = "add-option", text = add_option_text },
          {
            name = "|optpack.install()| or |optpack.update()| option",
            tag_name = "install-or-update-option",
            text = install_or_update_option_text,
          },
          { name = "Plugin", tag_name = "plugin", text = plugin_text },
          { name = "|optpack.set_default()| setting", tag_name = "setting", text = setting_text },
        })
      end,
    },
    {
      name = "EXAMPLES",
      body = function()
        return util.help_code_block_from_file(example_path)
      end,
    },
  },
})

local gen_readme = function()
  local f = io.open(example_path, "r")
  local exmaple = f:read("*a")
  f:close()

  local content = ([[
# %s

This is a neovim plugin manager that uses only opt package.

## Example

```lua
%s```]]):format(full_plugin_name, exmaple)

  local readme = io.open("README.md", "w")
  readme:write(content)
  readme:close()
end
gen_readme()
