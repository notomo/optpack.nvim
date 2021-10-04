local helper = require("optpack.lib.testlib.helper")
local optpack = helper.require("optpack")

local packpath_name = "mypackpath"

local plugin_name1 = "myplugin_name1"
local plugin1 = "account_name/" .. plugin_name1
local plugin_name2 = "myplugin_name2"
local plugin2 = "account_name/" .. plugin_name2

local create_plugin = function(name)
  helper.cleanup_loaded_modules(name)

  local opt_dir = packpath_name .. "/pack/optpack/opt"
  local root_dir = ("%s/%s"):format(opt_dir, name)

  local plugin_dir = ("%s/plugin/"):format(root_dir)
  helper.new_directory(plugin_dir)
  helper.new_file(plugin_dir .. name .. ".vim", [[
command! MyPluginTest echo ''
]])

  local lua_dir = ("%s/lua/%s/"):format(root_dir, name)
  helper.new_directory(lua_dir)
  helper.new_file(lua_dir .. "init.lua", [[
return "ok"
]])
end

describe("optpack.add()", function()

  before_each(function()
    helper.before_each()
    create_plugin(plugin_name1)
    create_plugin(plugin_name2)

    vim.o.packpath = helper.test_data_dir .. packpath_name
  end)
  after_each(helper.after_each)

  it("can set a plugin that is loaded by `packadd`", function()
    optpack.add(plugin1)
    vim.cmd("packadd " .. plugin_name1)

    local got = require(plugin_name1)
    assert.is_same("ok", got)
  end)

  it("can set a plugin that is loaded by filetype", function()
    optpack.add(plugin1, {load_on = {filetypes = {"lua"}}})
    vim.bo.filetype = "lua"

    local got = require(plugin_name1)
    assert.is_same("ok", got)
  end)

  it("can set plugins that is loaded by filetype", function()
    optpack.add(plugin1, {load_on = {filetypes = {"lua"}}})
    optpack.add(plugin2, {load_on = {filetypes = {"lua"}}})
    vim.bo.filetype = "lua"

    assert.is_same("ok", require(plugin_name1))
    assert.is_same("ok", require(plugin_name2))
  end)

  it("can set a plugin that is loaded by command", function()
    optpack.add(plugin1, {load_on = {cmds = {"MyPlugin*"}}})
    vim.cmd("MyPluginTest")

    local got = require(plugin_name1)
    assert.is_same("ok", got)
  end)

  it("can set a plugin that is loaded by event", function()
    optpack.add(plugin1, {load_on = {events = {"TabNew"}}})
    vim.cmd("tabedit")

    local got = require(plugin_name1)
    assert.is_same("ok", got)
  end)

  it("can set a plugin that is loaded by requiring module", function()
    optpack.add(plugin1, {load_on = {modules = {plugin_name1}}})

    local got = require(plugin_name1)
    assert.is_same("ok", got)
  end)

  it("can disable a plugin with enabled=false", function()
    optpack.add(plugin1)
    optpack.add(plugin1, {enabled = false})

    local got = optpack.list()
    assert.is_same({}, got)
  end)

  it("can set a hook pre_load by module loading", function()
    local called = false
    optpack.add(plugin1, {
      hooks = {
        pre_load = function()
          called = true
        end,
      },
      load_on = {modules = {plugin_name1}},
    })
    require(plugin_name1)

    assert.is_true(called)
  end)

  it("can set a hook post_load by module loading", function()
    local called = false
    optpack.add(plugin1, {
      hooks = {
        pre_load = function()
          called = false
        end,
        post_load = function()
          called = true
          require(plugin_name1)
        end,
      },
      load_on = {modules = {plugin_name1}},
    })
    require(plugin_name1)

    assert.is_true(called)
  end)

  it("can set a hook pre_load by filetype loading", function()
    local called = false
    optpack.add(plugin1, {
      hooks = {
        pre_load = function()
          called = true
        end,
      },
      load_on = {filetypes = {"lua"}},
    })
    vim.bo.filetype = "lua"

    assert.is_true(called)
  end)

  it("can set a hook post_load by filetype loading", function()
    local called = false
    optpack.add(plugin1, {
      hooks = {
        pre_load = function()
          called = false
        end,
        post_load = function()
          called = true
        end,
      },
      load_on = {filetypes = {"lua"}},
    })
    vim.bo.filetype = "lua"

    assert.is_true(called)
  end)

  it("can set a hook post_add", function()
    local called = false
    optpack.add(plugin1, {
      hooks = {
        post_add = function()
          called = true
        end,
      },
    })

    assert.is_true(called)
  end)

  it("executes hooks only once", function()
    local called = 0
    optpack.add(plugin1, {
      hooks = {
        pre_load = function()
          called = called + 1
        end,
      },
      load_on = {filetypes = {"lua"}, events = {"TabNew"}},
    })
    vim.bo.filetype = "lua"
    vim.cmd("tabedit")

    assert.is_same(1, called)
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

  it("installs plugins if directories do not exist", function()
    local mock = helper.require("optpack.lib.testlib.git_mock").Git.new()

    optpack.add("account1/test1", {fetch = {engine = mock}})
    optpack.add("account2/test2", {fetch = {engine = mock}})

    optpack.update()

    assert.is_same("https://github.com/account1/test1.git", mock.cloned[1].url)
    assert.is_same("https://github.com/account2/test2.git", mock.cloned[2].url)
    assert.length(mock.pulled, 2)

    -- TODO: assert view
  end)

  it("updates plugins if directories exist", function()
    create_plugin("test1")
    create_plugin("test2")
    vim.o.packpath = helper.test_data_dir .. packpath_name

    local mock = helper.require("optpack.lib.testlib.git_mock").Git.new()

    optpack.add("account1/test1", {fetch = {engine = mock}})
    optpack.add("account2/test2", {fetch = {engine = mock}})

    optpack.update()

    assert.length(mock.cloned, 0)
    assert.length(mock.pulled, 2)

    -- TODO: assert view
  end)

end)
