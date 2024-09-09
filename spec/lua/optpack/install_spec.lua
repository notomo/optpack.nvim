local helper = require("optpack.test.helper")
local optpack = helper.require("optpack")
local assert = helper.typed_assert(assert)

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

    optpack.add("account1/test1", { fetch = { base_url = git_server.url } })
    optpack.add("account2/test2", { fetch = { base_url = git_server.url } })

    local on_finished = helper.on_finished()
    optpack.install({ on_finished = on_finished })
    on_finished:wait()

    assert.exists_dir(helper.packpath_name .. "/pack/optpack/opt/test1")
    assert.exists_dir(helper.packpath_name .. "/pack/optpack/opt/test2")

    assert.window_count(2)
    assert.exists_pattern([[\v^\> Start installing\.$]])
    assert.exists_pattern([[\v^test1 \> Installed\.$]])
    assert.exists_pattern([[\v^test2 \> Installed\.$]])
    assert.current_line([[> Finished installing.]])
  end)

  it("does nothing if directories exist", function()
    helper.create_plugin_dir("test1")
    helper.create_plugin_dir("test2")
    helper.set_packpath()

    optpack.add("account1/test1", { fetch = { base_url = git_server.url } })
    optpack.add("account2/test2", { fetch = { base_url = git_server.url } })

    local on_finished = helper.on_finished()
    optpack.install({ on_finished = on_finished })
    on_finished:wait()

    assert.no.exists_pattern([[test1 > Installed.]])
    assert.no.exists_pattern([[test2 > Installed.]])
  end)

  it("can install plugins that are matched with pattern", function()
    helper.set_packpath()

    optpack.add("account1/test1", { fetch = { base_url = git_server.url } })
    optpack.add("account2/test2", { fetch = { base_url = git_server.url } })

    local on_finished = helper.on_finished()
    optpack.install({ on_finished = on_finished, pattern = "test2" })
    on_finished:wait()

    assert.exists_dir(helper.packpath_name .. "/pack/optpack/opt/test2")

    assert.no.exists_pattern([[test1 > Installed.]])
    assert.exists_pattern([[test2 > Installed.]])
  end)

  it("does not raise an error event if output buffer already exists", function()
    do
      local on_finished = helper.on_finished()
      optpack.install({ on_finished = on_finished })
      on_finished:wait()
    end
    do
      local on_finished = helper.on_finished()
      optpack.install({ on_finished = on_finished })
      on_finished:wait()
    end
    assert.buffer_full_name("optpack://optpack-install")
  end)

  it("can set default option by optpack.set_default()", function()
    optpack.set_default({ install_or_update = { pattern = "invalid" } })
    helper.set_packpath()

    optpack.add("account1/test1", { fetch = { base_url = git_server.url } })

    local on_finished = helper.on_finished()
    optpack.install({ on_finished = on_finished })
    on_finished:wait()

    assert.no.exists_pattern([[test1 > Installed.]])
  end)

  it("exexutes post_install hook", function()
    helper.set_packpath()

    local installed
    optpack.add("account1/test1", {
      fetch = { base_url = git_server.url },
      hooks = {
        post_install = function(plugin)
          installed = plugin.name
        end,
      },
    })

    local on_finished = helper.on_finished()
    optpack.install({ on_finished = on_finished })
    on_finished:wait()

    assert.equal("test1", installed)
  end)

  it("raises an error if pattern is invalid", function()
    local ok, err = pcall(function()
      optpack.install({ pattern = [[\(test]] })
    end)
    assert.is_false(ok)
    assert.match([[invalid pattern]], err)
  end)

  it("can disable buffer outputter", function()
    local on_finished = helper.on_finished()
    optpack.install({
      on_finished = on_finished,
      outputters = {
        buffer = { enabled = false },
      },
    })
    on_finished:wait()

    assert.window_count(1)
  end)

  it("can use echo outputter", function()
    helper.set_packpath()

    optpack.add("account1/test1", { fetch = { base_url = git_server.url } })
    optpack.add("account2/test2", { fetch = { base_url = git_server.url } })

    local on_finished = helper.on_finished()
    optpack.install({
      on_finished = on_finished,
      outputters = {
        buffer = { enabled = false },
        echo = { enabled = true },
      },
    })
    on_finished:wait()

    assert.exists_message([[%[optpack%] > Start installing.]])
  end)

  it("can use log outputter", function()
    helper.set_packpath()

    optpack.add("account1/test1", { fetch = { base_url = git_server.url } })
    optpack.add("account2/test2", { fetch = { base_url = git_server.url } })

    local log_path = helper.test_data:path("test.log")

    local on_finished = helper.on_finished()
    optpack.install({
      on_finished = on_finished,
      outputters = {
        buffer = { enabled = false },
        log = {
          enabled = true,
          path = log_path,
        },
      },
    })
    on_finished:wait()

    vim.cmd.edit(log_path)
    assert.exists_pattern([[> Start installing.]])
  end)
end)
