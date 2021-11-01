local helper = require("optpack.lib.testlib.helper")
local ParallelLimitter = helper.require("optpack.lib.parallel_limitter").ParallelLimitter
local Promise = require("optpack.lib.promise").Promise

describe("ParallelLimitter", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("consumes all added task", function()
    local call_count = 0
    local parallel = ParallelLimitter.new(8, 10)
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

end)
