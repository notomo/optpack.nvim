local helper = require("optpack.test.helper")
local optpack = helper.require("optpack")
local assert = helper.typed_assert(assert)

describe("optpack.update()", function()
  local git_server

  lazy_setup(function()
    git_server = helper.git_server()
    git_server:create_repository("account1/test1", {
      commits = {
        main = { "commit1", "commit2" },
        another1 = { "commit_a", "commit_b" },
      },
    })
    git_server:create_repository("account2/test2", {
      commits = {
        main = { "commit3", "commit4" },
        another2 = { "commit_c", "commit_d" },
      },
    })
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
    optpack.update({ on_finished = on_finished })
    on_finished:wait()

    assert.exists_dir(helper.packpath_name .. "/pack/optpack/opt/test1")
    assert.exists_dir(helper.packpath_name .. "/pack/optpack/opt/test2")

    assert.window_count(2)
    assert.exists_pattern([[\v^\> Start updating\.$]])
    assert.exists_pattern([[\v^test1 \> Installed\.$]])
    assert.exists_pattern([[\v^test2 \> Installed\.$]])
    assert.current_line([[> Finished updating.]])
  end)

  it("updates plugins if directories exist", function()
    git_server.client:clone("account1/test1", helper.plugin_dir("test1"))
    git_server.client:reset_hard("HEAD~~", helper.plugin_dir("test1"))
    git_server.client:clone("account2/test2", helper.plugin_dir("test2"))

    helper.set_packpath()

    optpack.add("account1/test1", { fetch = { base_url = git_server.url } })
    optpack.add("account2/test2", { fetch = { base_url = git_server.url } })

    local on_finished = helper.on_finished()
    optpack.update({ on_finished = on_finished })

    -- to test work with other buffer
    local bufnr = vim.api.nvim_get_current_buf()
    vim.cmd.tabedit()

    on_finished:wait()

    vim.cmd.buffer(bufnr)
    assert.exists_pattern([[test1 > Updated.]])
    assert.exists_pattern([[test1 > ....... commit1]])
    assert.exists_pattern([[test1 > ....... commit2]])
    assert.no.exists_pattern([[test2 > Updated.]])

    assert.match(".......%.%.%.......", vim.b.optpack_updates["2"].revision_range)
    assert.equal(helper.plugin_dir("test1"), vim.b.optpack_updates["2"].directory)
  end)

  it("can update plugins that are matched with pattern", function()
    git_server.client:clone("account1/test1", helper.plugin_dir("test1"))
    git_server.client:reset_hard("HEAD~~", helper.plugin_dir("test1"))
    git_server.client:clone("account2/test2", helper.plugin_dir("test2"))
    git_server.client:reset_hard("HEAD~~", helper.plugin_dir("test2"))

    helper.set_packpath()

    optpack.add("account1/test1", { fetch = { base_url = git_server.url } })
    optpack.add("account2/test2", { fetch = { base_url = git_server.url } })

    local on_finished = helper.on_finished()
    optpack.update({ on_finished = on_finished, pattern = "test2" })
    on_finished:wait()

    assert.no.exists_pattern([[test1 > Updated.]])
    assert.exists_pattern([[test2 > Updated.]])
  end)

  it("can update with specified branch", function()
    git_server.client:clone("account1/test1", helper.plugin_dir("test1"))
    git_server.client:switch(helper.plugin_dir("test1"), "another1")
    git_server.client:reset_hard("HEAD~~", helper.plugin_dir("test1"))
    git_server.client:switch(helper.plugin_dir("test1"), "main")

    git_server.client:clone("account2/test2", helper.plugin_dir("test2"))
    git_server.client:switch(helper.plugin_dir("test2"), "another2")
    git_server.client:reset_hard("HEAD~~", helper.plugin_dir("test2"))

    helper.set_packpath()

    optpack.add("account1/test1", { fetch = {
      base_url = git_server.url,
      version = "another1",
    } })
    optpack.add("account2/test2", { fetch = {
      base_url = git_server.url,
      version = "another2",
    } })

    local on_finished = helper.on_finished()
    optpack.update({ on_finished = on_finished })
    on_finished:wait()

    assert.exists_pattern([[test1 > Updated.]])
    assert.exists_pattern([[test2 > Updated.]])

    assert.equal("another1", git_server.client:branch(helper.plugin_dir("test1")))
    assert.equal("another2", git_server.client:branch(helper.plugin_dir("test2")))
  end)

  it("shows error if non-git repository directory exists", function()
    helper.create_plugin_dir("test1")

    helper.set_packpath()

    optpack.add("account1/test1", { fetch = { base_url = git_server.url } })

    local on_finished = helper.on_finished()
    optpack.update({ on_finished = on_finished })
    on_finished:wait()

    assert.exists_pattern([[test1 > git --git-dir ]])
    assert.exists_pattern([[test1 > fatal: not a git repository]])
  end)

  it("does not raise an error event if output buffer already exists", function()
    do
      local on_finished = helper.on_finished()
      optpack.update({ on_finished = on_finished })
      on_finished:wait()
    end
    do
      local on_finished = helper.on_finished()
      optpack.update({ on_finished = on_finished })
      on_finished:wait()
    end
    assert.buffer_full_name("optpack://optpack-update")
  end)

  it("can set default option by optpack.set_default()", function()
    optpack.set_default({ install_or_update = { pattern = "invalid" } })
    helper.set_packpath()

    optpack.add("account1/test1", { fetch = { base_url = git_server.url } })

    local on_finished = helper.on_finished()
    optpack.update({ on_finished = on_finished })
    on_finished:wait()

    assert.no.exists_pattern([[test1 > Installed.]])
  end)

  it("exexutes post_update hook", function()
    git_server.client:clone("account1/test1", helper.plugin_dir("test1"))
    git_server.client:reset_hard("HEAD~~", helper.plugin_dir("test1"))

    helper.set_packpath()

    local updated
    optpack.add("account1/test1", {
      fetch = { base_url = git_server.url },
      hooks = {
        post_update = function(plugin)
          updated = plugin.name
        end,
      },
    })

    local on_finished = helper.on_finished()
    optpack.update({ on_finished = on_finished })
    on_finished:wait()

    assert.equal("test1", updated)
  end)

  it("raises an error if pattern is invalid", function()
    local ok, err = pcall(function()
      optpack.update({ pattern = [[\(test]] })
    end)
    assert.is_false(ok)
    assert.match([[invalid pattern]], err)
  end)
end)
