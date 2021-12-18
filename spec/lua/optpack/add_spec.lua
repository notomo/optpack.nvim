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
    optpack.add(plugin1, {load_on = {events = {{"BufNewFile", "*.txt"}}}})

    vim.cmd("edit test")
    assert.no.can_require(plugin_name1)

    vim.cmd("edit test.txt")
    assert.can_require(plugin_name1)
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
        pre_load = function(plugin)
          called = plugin.name
        end,
      },
      load_on = {modules = {plugin_name1}},
    })
    require(plugin_name1)

    assert.equal(plugin_name1, called)
  end)

  it("can set a hook post_load by module loading", function()
    local called = false
    optpack.add(plugin1, {
      hooks = {
        pre_load = function()
          called = false
        end,
        post_load = function(plugin)
          called = plugin.name
          require(plugin_name1)
        end,
      },
      load_on = {modules = {plugin_name1}},
    })
    require(plugin_name1)

    assert.equal(plugin_name1, called)
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
    local added
    optpack.add(plugin1, {
      hooks = {
        post_add = function(plugin)
          added = plugin.name
        end,
      },
    })

    assert.equal(plugin_name1, added)
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

  it("can set default option by optpack.set_default()", function()
    local called = false
    optpack.set_default({
      add = {
        hooks = {
          post_add = function()
            called = true
          end,
        },
      },
    })

    optpack.add("account1/test1")

    assert.is_true(called)
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

  it("show an error message if unexpected plugin is loaded", function()
    local unexpected_packpath = "_unexpected"
    helper.create_plugin_dir(plugin_name1, {opt_path = unexpected_packpath .. "/pack/optpack/opt/"})

    optpack.add(plugin1)
    vim.o.packpath = helper.test_data_dir .. unexpected_packpath

    optpack.load(plugin_name1)

    assert.exists_message([[failed to load expected directory: ]] .. helper.test_data_dir .. helper.opt_path .. plugin_name1)
  end)

  it("show an error message if hooks.post_add raises an error", function()
    optpack.add(plugin1, {
      hooks = {
        post_add = function()
          error("test error", 0)
        end,
      },
    })

    assert.exists_message(plugin_name1 .. [[: post_add: test error]])
  end)

  it("show an error message if hooks.pre_load raises an error", function()
    optpack.add(plugin1, {
      hooks = {
        pre_load = function()
          error("test error", 0)
        end,
      },
    })

    optpack.load(plugin_name1)

    assert.exists_message(plugin_name1 .. [[: pre_load: test error]])
  end)

  it("show an error message if hooks.post_load raises an error", function()
    optpack.add(plugin1, {
      hooks = {
        post_load = function()
          error("test error", 0)
        end,
      },
    })

    optpack.load(plugin_name1)

    assert.exists_message(plugin_name1 .. [[: post_load: test error]])
  end)

end)
