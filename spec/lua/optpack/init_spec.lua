local helper = require("optpack.lib.testlib.helper")
local optpack = helper.require("optpack")

describe("optpack.add()", function()

  local packpath_name = "mypackpath"
  local plugin_name = "myplugin_name"
  local plugin = "account_name/" .. plugin_name

  before_each(function()
    helper.before_each()
    vim.o.runtimepath = helper.runtimepath

    local opt_dir = packpath_name .. "/pack/optpack/opt"
    local root_dir = ("%s/%s"):format(opt_dir, plugin_name)

    local plugin_dir = ("%s/plugin/"):format(root_dir)
    helper.new_directory(plugin_dir)
    helper.new_file(plugin_dir .. plugin_name .. ".vim", [[
command! MyPluginTest echo ''
]])

    local lua_dir = ("%s/lua/%s/"):format(root_dir, plugin_name)
    helper.new_directory(lua_dir)
    helper.new_file(lua_dir .. "init.lua", [[
return "ok"
]])

    vim.o.packpath = helper.test_data_dir .. packpath_name
  end)
  after_each(helper.after_each)

  it("can set a plugin that is loaded by `packadd`", function()
    optpack.add(plugin)
    vim.cmd("packadd " .. plugin_name)

    local got = require(plugin_name)
    assert.is_same("ok", got)
  end)

  it("can set a plugin that is loaded by filetype", function()
    optpack.add(plugin, {load_on = {filetypes = {"lua"}}})
    vim.bo.filetype = "lua"

    local got = require(plugin_name)
    assert.is_same("ok", got)
  end)

  it("can set a plugin that is loaded by command", function()
    optpack.add(plugin, {load_on = {cmds = {"MyPlugin*"}}})
    vim.cmd("MyPluginTest")

    local got = require(plugin_name)
    assert.is_same("ok", got)
  end)

  it("can set a plugin that is loaded by event", function()
    optpack.add(plugin, {load_on = {events = {"TabNew"}}})
    vim.cmd("tabedit")

    local got = require(plugin_name)
    assert.is_same("ok", got)
  end)

  it("can set a plugin that is loaded by requiring module", function()
    optpack.add(plugin, {load_on = {modules = {plugin_name}}})

    local got = require(plugin_name)
    assert.is_same("ok", got)
  end)

  it("can disable a plugin with enabled=false", function()
    optpack.add(plugin)
    optpack.add(plugin, {enabled = false})

    local got = optpack.list()
    assert.is_same({}, got)
  end)

end)

describe("optpack.list()", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("returns empty table if there is no packages", function()
    local got = optpack.list()
    assert.is_same({}, got)
  end)

  it("returns packages", function()
    optpack.add("account/test")

    local got = optpack.list()[1]
    assert.is_same({name = "account/test"}, got)
  end)

end)

describe("optpack.update()", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("TODO", function()
  end)

end)
