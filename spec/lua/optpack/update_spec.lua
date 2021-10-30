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
    git_server.client:clone("account1/test1", helper.plugin_dir("test1"))
    git_server.client:reset_hard("HEAD~~", helper.plugin_dir("test1"))
    git_server.client:clone("account2/test2", helper.plugin_dir("test2"))

    helper.set_packpath()

    optpack.add("account1/test1", {fetch = {base_url = git_server.url}})
    optpack.add("account2/test2", {fetch = {base_url = git_server.url}})

    local on_finished = helper.on_finished()
    optpack.update({on_finished = on_finished, parallel_interval = helper.parallel_interval})
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
    optpack.update({
      on_finished = on_finished,
      parallel_interval = helper.parallel_interval,
      pattern = "test2",
    })
    on_finished:wait()

    assert.no.exists_pattern([[test1 > Updated.]])
    assert.exists_pattern([[test2 > Updated.]])
  end)

end)

