local helper = require("optpack.lib.testlib.helper")
local optpack = helper.require("optpack")

describe("optpack.add()", function()

  local plugin_name1 = "myplugin_name1"
  local plugin1 = "account_name/" .. plugin_name1

  local plugin_name2 = "myplugin_name2"
  local plugin2 = "account_name/" .. plugin_name2

  before_each(function()
    helper.before_each()
    helper.create_plugin_dir(plugin_name1, {
      plugin_vim_content = [[
command! MyPluginTest echo ''
]],
    })
    helper.create_plugin_dir(plugin_name2)
    helper.set_packpath()
  end)
  after_each(helper.after_each)

  it("can set a plugin that is loaded by `packadd`", function()
    optpack.add(plugin1)
    vim.cmd("packadd " .. plugin_name1)

    assert.can_require(plugin_name1)
  end)

  it("can set a plugin that is loaded by filetype", function()
    optpack.add(plugin1, {load_on = {filetypes = {"lua"}}})
    vim.bo.filetype = "lua"

    assert.can_require(plugin_name1)
  end)

  it("can set plugins that is loaded by filetype", function()
    optpack.add(plugin1, {load_on = {filetypes = {"lua"}}})
    optpack.add(plugin2, {load_on = {filetypes = {"lua"}}})
    vim.bo.filetype = "lua"

    assert.can_require(plugin_name1)
    assert.can_require(plugin_name2)
  end)

  it("can set a plugin that is loaded by command", function()
    optpack.add(plugin1, {load_on = {cmds = {"MyPlugin*"}}})
    vim.cmd("MyPluginTest")

    assert.can_require(plugin_name1)
  end)

  it("can set a plugin that is loaded by event only", function()
    optpack.add(plugin1, {load_on = {events = {"TabNew"}}})
    vim.cmd("tabedit")

    assert.can_require(plugin_name1)
  end)

  it("can set a plugin that is loaded by event with pattern", function()
    local called = false
    optpack.add(plugin1, {
      hooks = {
        post_load = function()
          called = true
        end,
      },
      load_on = {events = {{"BufNewFile", "*.txt"}}},
    })

    vim.cmd("edit test")
    assert.is_false(called)

    vim.cmd("edit test.txt")
    assert.is_true(called)
  end)

  it("can set a plugin that is loaded by requiring module", function()
    optpack.add(plugin1, {load_on = {modules = {plugin_name1}}})

    assert.can_require(plugin_name1)
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
    helper.set_packpath()

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

  local git_server

  lazy_setup(function()
    git_server = helper.git_server()
    git_server:create_repository("account1/test1")
    git_server:create_repository("account2/test2")
  end)
  lazy_teardown(function()
    git_server:teardown()
  end)

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("installs plugins if directories do not exist", function()
    helper.set_packpath()

    optpack.add("account1/test1", {fetch = {base_url = git_server.url}})
    optpack.add("account2/test2", {fetch = {base_url = git_server.url}})

    local on_finished = helper.on_finished()
    optpack.update({on_finished = on_finished, parallel_interval = helper.parallel_interval})
    on_finished:wait()

    assert.exists_dir(helper.packpath_name .. "/pack/optpack/opt/test1")
    assert.exists_dir(helper.packpath_name .. "/pack/optpack/opt/test2")

    assert.window_count(2)
    assert.exists_pattern([[test1 > Installed.]])
    assert.exists_pattern([[test2 > Installed.]])
  end)

  it("updates plugins if directories exist", function()
    helper.create_plugin_dir("test1")
    helper.create_plugin_dir("test2")
    helper.set_packpath()

    optpack.add("account1/test1", {fetch = {base_url = git_server.url}})
    optpack.add("account2/test2", {fetch = {base_url = git_server.url}})

    local on_finished = helper.on_finished()
    optpack.update({on_finished = on_finished, parallel_interval = helper.parallel_interval})
    on_finished:wait()

    -- TODO: assert view
  end)

  it("can update plugins that are matched with pattern", function()
    helper.create_plugin_dir("test1")
    helper.create_plugin_dir("test2")
    helper.set_packpath()

    optpack.add("account1/test1", {fetch = {base_url = git_server.url}})
    optpack.add("account2/test2", {fetch = {base_url = git_server.url}})

    local on_finished = helper.on_finished()
    optpack.update({
      on_finished = on_finished,
      parallel_interval = helper.parallel_interval,
      pattern = "test2",
    })
    on_finished:wait()

    -- TODO: assert view
  end)

end)

describe("optpack.install()", function()

  local git_server

  lazy_setup(function()
    git_server = helper.git_server()
    git_server:create_repository("account1/test1")
    git_server:create_repository("account2/test2")
  end)
  lazy_teardown(function()
    git_server:teardown()
  end)

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("installs plugins if directories do not exist", function()
    helper.set_packpath()

    optpack.add("account1/test1", {fetch = {base_url = git_server.url}})
    optpack.add("account2/test2", {fetch = {base_url = git_server.url}})

    local on_finished = helper.on_finished()
    optpack.install({on_finished = on_finished, parallel_interval = helper.parallel_interval})
    on_finished:wait()

    assert.exists_dir(helper.packpath_name .. "/pack/optpack/opt/test1")
    assert.exists_dir(helper.packpath_name .. "/pack/optpack/opt/test2")

    assert.window_count(2)
    assert.exists_pattern([[test1 > Installed.]])
    assert.exists_pattern([[test2 > Installed.]])
  end)

  it("does nothing if directories exist", function()
    helper.create_plugin_dir("test1")
    helper.create_plugin_dir("test2")
    helper.set_packpath()

    optpack.add("account1/test1", {fetch = {base_url = git_server.url}})
    optpack.add("account2/test2", {fetch = {base_url = git_server.url}})

    local on_finished = helper.on_finished()
    optpack.install({on_finished = on_finished, parallel_interval = helper.parallel_interval})
    on_finished:wait()

    assert.no.exists_pattern([[test1 > Installed.]])
    assert.no.exists_pattern([[test2 > Installed.]])
  end)

  it("can install plugins that are matched with pattern", function()
    helper.set_packpath()

    optpack.add("account1/test1", {fetch = {base_url = git_server.url}})
    optpack.add("account2/test2", {fetch = {base_url = git_server.url}})

    local on_finished = helper.on_finished()
    optpack.install({
      on_finished = on_finished,
      parallel_interval = helper.parallel_interval,
      pattern = "test2",
    })
    on_finished:wait()

    assert.exists_dir(helper.packpath_name .. "/pack/optpack/opt/test2")

    assert.no.exists_pattern([[test1 > Installed.]])
    assert.exists_pattern([[test2 > Installed.]])
  end)

end)

describe("optpack.load()", function()

  local plugin_name1 = "myplugin_name1"
  local plugin1 = "account_name/" .. plugin_name1

  before_each(function()
    helper.before_each()
    helper.create_plugin_dir(plugin_name1)
    helper.set_packpath()
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

    assert.can_require(plugin_name1)
    assert.is_true(called)
  end)

end)
