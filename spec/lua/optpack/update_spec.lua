local helper = require("optpack.lib.testlib.helper")
local optpack = helper.require("optpack")

describe("optpack.update()", function()

  local git_server

  lazy_setup(function()
    git_server = helper.git_server()
    git_server:create_repository("account1/test1", {"commit1", "commit2"})
    git_server:create_repository("account2/test2", {"commit3", "commit4"})
  end)
  lazy_teardown(function()
    git_server:teardown()
  end)

  before_each(function()
    helper.before_each()
    optpack.set_default({install_or_update = {parallel = {interval = helper.parallel_interval}}})
  end)
  after_each(helper.after_each)

  it("installs plugins if directories do not exist", function()
    helper.set_packpath()

    optpack.add("account1/test1", {fetch = {base_url = git_server.url}})
    optpack.add("account2/test2", {fetch = {base_url = git_server.url}})

    local on_finished = helper.on_finished()
    optpack.update({on_finished = on_finished})
    on_finished:wait()

    assert.exists_dir(helper.packpath_name .. "/pack/optpack/opt/test1")
    assert.exists_dir(helper.packpath_name .. "/pack/optpack/opt/test2")

    assert.window_count(2)
    assert.exists_pattern([[test1 > Installed.]])
    assert.exists_pattern([[test2 > Installed.]])
  end)

  it("updates plugins if directories exist", function()
    git_server.client:clone("account1/test1", helper.plugin_dir("test1"))
    git_server.client:reset_hard("HEAD~~", helper.plugin_dir("test1"))
    git_server.client:clone("account2/test2", helper.plugin_dir("test2"))

    helper.set_packpath()

    optpack.add("account1/test1", {fetch = {base_url = git_server.url}})
    optpack.add("account2/test2", {fetch = {base_url = git_server.url}})

    local on_finished = helper.on_finished()
    optpack.update({on_finished = on_finished})
    on_finished:wait()

    assert.exists_pattern([[test1 > Updated.]])
    assert.no.exists_pattern([[test2 > Updated.]])
  end)

  it("can update plugins that are matched with pattern", function()
    git_server.client:clone("account1/test1", helper.plugin_dir("test1"))
    git_server.client:reset_hard("HEAD~~", helper.plugin_dir("test1"))
    git_server.client:clone("account2/test2", helper.plugin_dir("test2"))
    git_server.client:reset_hard("HEAD~~", helper.plugin_dir("test2"))

    helper.set_packpath()

    optpack.add("account1/test1", {fetch = {base_url = git_server.url}})
    optpack.add("account2/test2", {fetch = {base_url = git_server.url}})

    local on_finished = helper.on_finished()
    optpack.update({on_finished = on_finished, pattern = "test2"})
    on_finished:wait()

    assert.no.exists_pattern([[test1 > Updated.]])
    assert.exists_pattern([[test2 > Updated.]])
  end)

  it("shows error if non-git repository directory exists", function()
    helper.create_plugin_dir("test1")

    helper.set_packpath()

    optpack.add("account1/test1", {fetch = {base_url = git_server.url}})

    local on_finished = helper.on_finished()
    optpack.update({on_finished = on_finished})
    on_finished:wait()

    assert.exists_pattern([[test1 > git --git-dir ]])
    assert.exists_pattern([[test1 > fatal: not a git repository]])
  end)

  it("does not raise an error event if output buffer already exists", function()
    do
      local on_finished = helper.on_finished()
      optpack.update({on_finished = on_finished})
      on_finished:wait()
    end
    do
      local on_finished = helper.on_finished()
      optpack.update({on_finished = on_finished})
      on_finished:wait()
    end
    assert.buffer_name("optpack://optpack-update")
  end)

  it("can set default option by optpack.set_default()", function()
    optpack.set_default({install_or_update = {pattern = "invalid"}})
    helper.set_packpath()

    optpack.add("account1/test1", {fetch = {base_url = git_server.url}})

    local on_finished = helper.on_finished()
    optpack.update({on_finished = on_finished})
    on_finished:wait()

    assert.no.exists_pattern([[test1 > Installed.]])
  end)

  it("exexutes post_update hook", function()
    git_server.client:clone("account1/test1", helper.plugin_dir("test1"))
    git_server.client:reset_hard("HEAD~~", helper.plugin_dir("test1"))

    helper.set_packpath()

    local updated
    optpack.add("account1/test1", {
      fetch = {base_url = git_server.url},
      hooks = {
        post_update = function(plugin)
          updated = plugin.name
        end,
      },
    })

    local on_finished = helper.on_finished()
    optpack.update({on_finished = on_finished})
    on_finished:wait()

    assert.equal("test1", updated)
  end)

end)

