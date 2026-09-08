local ntf = require("ntf")
local describe, it, before_each, after_each = ntf.describe, ntf.it, ntf.before_each, ntf.after_each
local helper = require("optpack.test.helper")
local assert = helper.typed_assert(ntf.assert)
local ParallelLimitter = require("optpack.lib.parallel_limitter")

local start = function(parallel)
  local on_finished = helper.on_finished()
  --- @async
  --- @return nil
  local run = function()
    parallel:start()
  end
  vim.async.run(run):on_complete(function()
    on_finished()
  end)
  on_finished:wait()
end

describe("ParallelLimitter", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("consumes all added task", function()
    local call_count = 0
    local parallel = ParallelLimitter.new(8)
    for _ = 1, 10 do
      parallel:add(function()
        call_count = call_count + 1
      end)
    end

    start(parallel)

    assert.equal(10, call_count)
  end)

  it("finishes even if exists failed task", function()
    local call_count = 0
    local parallel = ParallelLimitter.new(8)
    for _ = 1, 10 do
      --- @async
      --- @return nil
      local fail = function()
        vim.async.sleep(25)
        call_count = call_count + 1
        error("test error", 0)
      end
      parallel:add(fail)
    end

    start(parallel)

    assert.equal(10, call_count)
  end)

  it("finishes even if empty", function()
    local parallel = ParallelLimitter.new(1)
    start(parallel)
  end)

  it("finishes even if a few task", function()
    local call_count = 0
    local parallel = ParallelLimitter.new(10)
    for _ = 1, 2 do
      parallel:add(function()
        call_count = call_count + 1
      end)
    end

    start(parallel)

    assert.equal(2, call_count)
  end)
end)
