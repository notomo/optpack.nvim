local M = {}

--- @class OptpackAddOption
--- @field depends string[]? dependency plugin (not full) names. These will be loaded before. default: {}
--- @field enabled boolean? if enabled=false, optpack ignores the plugin. default: true
--- @field package_name string? used as the package directory name. your-packpath/pack/{package_name}/opt default: "optpack"
--- @field select_packpath (fun():string)? returns a directory path. default: returns the first element of 'packpath'
--- @field fetch OptpackAddOptionFetch? |OptpackAddOptionFetch|
--- @field hooks OptpackAddOptionHooks? |OptpackAddOptionHooks|
--- @field load_on OptpackAddOptionLoadOn? |OptpackAddOptionLoadOn|

--- @class OptpackAddOptionFetch
--- @field base_url string? A git server base url, default: "https://github.com"
--- @field depth integer? for shallow clone depth. Used full clone if depth < 1. default: 1

--- @class OptpackAddOptionHooks
--- @field post_add (fun(plugin:OptpackPlugin)|table)? called on after |optpack.add()|
--- @field pre_load (fun(plugin:OptpackPlugin)|table)? called on before loading
--- @field post_install (fun(plugin:OptpackPlugin)|table)? called on after installing
--- @field post_update (fun(plugin:OptpackPlugin)|table)? called on after updating
--- @field post_load (fun(plugin:OptpackPlugin)|table)? called on after loading

--- @class OptpackAddOptionLoadOn
--- @field cmds string[]? EX command pattern list, default: {}
--- @field events (string|string[])[]? autocmd event name or [name, pattern] list, default: {}
--- @field filetypes string[]? file type pattern list, default: {}
--- @field keymaps (fun(vim:table)|table)? set keymap function. (The argument is patched vim object)
---   example: function(vim) vim.keymap.set("n", "S", "<Plug>(example)") end
---   default: function() end
--- @field modules string[]? for require() lua module name list, default: {}

--- Add a plugin.
--- @param full_name string: {account_name}/{plugin_name} format
--- @param opts OptpackAddOption?: |OptpackAddOption|
function M.add(full_name, opts)
  require("optpack.command").add(full_name, opts)
end

--- @class OptpackPlugin
--- @field directory string full path of the plugin directory
--- @field full_name string {account_name}/{plugin_name} format plugin name
--- @field name string plugin name
--- @field url string git repository url
--- @field opts OptpackAddOption |OptpackAddOption|

--- Returns list of plugins.
--- @return OptpackPlugin[]: list of |OptpackPlugin|
function M.list()
  return require("optpack.command").list()
end

--- Returns a plugin.
--- @param plugin_name string:
--- @return OptpackPlugin: |OptpackPlugin|
function M.get(plugin_name)
  return require("optpack.command").get(plugin_name)
end

--- @class OptpackInstallOrUpdateOption
--- @field on_finished (fun(plugin:OptpackPlugin)|table)? called on finished updating or installing
--- @field outputters OptpackOutputters? outputter settings
--- @field parallel OptpackParallelOption? parallel setting
--- @field pattern string? target plugin name pattern for vim regex, default: ".*"

--- @class OptpackOutputters
--- @field buffer OptpackBufferOutputter? |OptpackBufferOutputter|
--- @field echo OptpackEchoOutputter? |OptpackEchoOutputter|
--- @field log OptpackLogOutputter? |OptpackLogOutputter|

--- @class OptpackBufferOutputter
--- @field enabled boolean? used if true. default: true
--- @field open (fun(bufnr:integer)|table)? open buffer

--- @class OptpackEchoOutputter
--- @field enabled boolean? used if true. default: true

--- @class OptpackLogOutputter
--- @field enabled boolean? used if true. default: true
--- @field path string? log file path: default: vim.fn.stdpath("cache")/optpack-update.log

--- @class OptpackParallelOption
--- @field limit integer? max number for parallel job, default: 8

--- Install plugins.
--- @param opts OptpackInstallOrUpdateOption?: |OptpackInstallOrUpdateOption|
function M.install(opts)
  require("optpack.command").install_or_update("install", opts)
end

--- Update plugins.
--- @param opts OptpackInstallOrUpdateOption?: |OptpackInstallOrUpdateOption|
function M.update(opts)
  require("optpack.command").install_or_update("update", opts)
end

--- Load a plugin.
--- @param plugin_name string:
function M.load(plugin_name)
  require("optpack.command").load(plugin_name)
end

-- helper
function M.load_by_expr_keymap(...)
  M.load(...)
  return ""
end

--- @class OptpackSetting
--- @field add OptpackAddOption? |OptpackAddOption|
--- @field install_or_update OptpackInstallOrUpdateOption? |OptpackInstallOrUpdateOption|

--- Set default setting.
--- @param setting OptpackSetting: |OptpackSetting|
function M.set_default(setting)
  require("optpack.command").set_default(setting)
end

return M
