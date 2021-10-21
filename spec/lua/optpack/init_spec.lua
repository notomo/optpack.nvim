local helper = require("optpack.lib.testlib.helper")
local optpack = helper.require("optpack")

-- small for test speed
local parallel_interval = 3

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

  it("does not execute hooks if plugin does not exist", function()
    local called = false
    optpack.add("account1/not_exist", {
      hooks = {
        pre_load = function()
          called = true
        end,
      },
    })
    optpack.load("not_exist")

    assert.is_false(called)
  end)

  it("overwrites the same name plugin", function()
    optpack.add("account1/test")
    optpack.add("account2/test")

    local got = optpack.list()[1]
    assert.is_same("account2/test", got.full_name)
  end)

end)

describe("optpack.list()", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("returns empty table if there is no plugins", function()
    local got = optpack.list()
    assert.is_same({}, got)
  end)

  it("returns plugins", function()
    vim.o.packpath = helper.test_data_dir .. packpath_name

    optpack.add("account/test")

    local got = optpack.list()[1]
    assert.is_same({
      full_name = "account/test",
      name = "test",
      directory = vim.o.packpath .. "/pack/optpack/opt/test",
      url = "https://github.com/account/test",
    }, got)
  end)

end)

describe("optpack.update()", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("installs plugins if directories do not exist", function()
    local job_factory = helper.job_factory()

    optpack.add("account1/test1", {fetch = {job_factory = job_factory}})
    optpack.add("account2/test2", {fetch = {job_factory = job_factory}})

    local on_finished = helper.on_finished()
    optpack.update({on_finished = on_finished, parallel_interval = parallel_interval})
    on_finished:wait()

    assert.window_count(2)
    -- TODO: assert view
  end)

  it("updates plugins if directories exist", function()
    create_plugin("test1")
    create_plugin("test2")
    vim.o.packpath = helper.test_data_dir .. packpath_name

    local job_factory = helper.job_factory()

    optpack.add("account1/test1", {fetch = {job_factory = job_factory}})
    optpack.add("account2/test2", {fetch = {job_factory = job_factory}})

    local on_finished = helper.on_finished()
    optpack.update({on_finished = on_finished, parallel_interval = parallel_interval})
    on_finished:wait()

    -- TODO: assert view
  end)

  it("can update plugins that are matched with pattern", function()
    create_plugin("test1")
    create_plugin("test2")
    vim.o.packpath = helper.test_data_dir .. packpath_name

    local job_factory = helper.job_factory()

    optpack.add("account1/test1", {fetch = {job_factory = job_factory}})
    optpack.add("account2/test2", {fetch = {job_factory = job_factory}})

    local on_finished = helper.on_finished()
    optpack.update({
      on_finished = on_finished,
      parallel_interval = parallel_interval,
      pattern = "test2",
    })
    on_finished:wait()

    -- TODO: assert view
  end)

end)

describe("optpack.install()", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("installs plugins if directories do not exist", function()
    local job_factory = helper.job_factory()

    optpack.add("account1/test1", {fetch = {job_factory = job_factory}})
    optpack.add("account2/test2", {fetch = {job_factory = job_factory}})

    local on_finished = helper.on_finished()
    optpack.install({on_finished = on_finished, parallel_interval = parallel_interval})
    on_finished:wait()

    assert.window_count(2)
    -- TODO: assert view
  end)

  it("does nothing if directories exist", function()
    create_plugin("test1")
    create_plugin("test2")
    vim.o.packpath = helper.test_data_dir .. packpath_name

    local job_factory = helper.job_factory()

    optpack.add("account1/test1", {fetch = {job_factory = job_factory}})
    optpack.add("account2/test2", {fetch = {job_factory = job_factory}})

    local on_finished = helper.on_finished()
    optpack.install({on_finished = on_finished, parallel_interval = parallel_interval})
    on_finished:wait()

    -- TODO: assert view
  end)

  it("can install plugins that are matched with pattern", function()
    local job_factory = helper.job_factory()

    optpack.add("account1/test1", {fetch = {job_factory = job_factory}})
    optpack.add("account2/test2", {fetch = {job_factory = job_factory}})

    local on_finished = helper.on_finished()
    optpack.install({
      on_finished = on_finished,
      parallel_interval = parallel_interval,
      pattern = "test2",
    })
    on_finished:wait()

    -- TODO: assert view
  end)

end)

describe("optpack.load()", function()

  before_each(function()
    helper.before_each()
    create_plugin(plugin_name1)

    vim.o.packpath = helper.test_data_dir .. packpath_name
  end)
  after_each(helper.after_each)

  it("loads a plugin with hook", function()
    local called = false
    optpack.add(plugin1, {
      hooks = {
        pre_load = function()
          called = true
        end,
      },
    })

    optpack.load(plugin_name1)

    local got = require(plugin_name1)
    assert.is_same("ok", got)
    assert.is_true(called)
  end)

end)
