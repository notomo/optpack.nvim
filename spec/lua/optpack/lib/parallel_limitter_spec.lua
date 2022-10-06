local helper = require("optpack.test.helper")
local ParallelLimitter = require("optpack.lib.parallel_limitter")
local Promise = require("optpack.vendor.promise")

describe("ParallelLimitter", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("consumes all added task", function()
    local call_count = 0
    local parallel = ParallelLimitter.new(8)
    for _ = 1, 10 do
      parallel:add(function()
        call_count = call_count + 1
        return Promise.resolve()
      end)
    end

    local on_finished = helper.on_finished()
    parallel:start():finally(function()
      on_finished()
    end)
    on_finished:wait()

    assert.equal(10, call_count)
  end)

  it("finishes even if exists rejected promise", function()
    local call_count = 0
    local parallel = ParallelLimitter.new(8)
    for _ = 1, 10 do
      parallel:add(function()
        return Promise.new(function(_, reject)
          vim.defer_fn(function()
            call_count = call_count + 1
            reject()
          end, 25)
        end)
      end)
    end

    local on_finished = helper.on_finished()
    parallel:start():finally(function()
      on_finished()
    end)
    on_finished:wait()

    assert.equal(10, call_count)
  end)

  it("finishes even if empty", function()
    local parallel = ParallelLimitter.new(1)
    local on_finished = helper.on_finished()
    parallel:start():finally(function()
      on_finished()
    end)
    on_finished:wait()
  end)

  it("finishes even if a few task", function()
    local call_count = 0
    local parallel = ParallelLimitter.new(10)
    for _ = 1, 2 do
      parallel:add(function()
        call_count = call_count + 1
        return Promise.resolve()
      end)
    end

    local on_finished = helper.on_finished()
    parallel:start():finally(function()
      on_finished()
    end)
    on_finished:wait()

    assert.equal(2, call_count)
  end)
end)
