local helper = require("optpack.lib.testlib.helper")
local Promise = helper.require("optpack.lib.promise").Promise

describe("promise:next()", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can chain with non-promise", function()
    local want = "ok"
    local got
    local on_finished = helper.on_finished()
    Promise.new(function(resolve)
      resolve(want)
    end):next(function(v)
      return v
    end):next(function(v)
      got = v
      on_finished()
    end)
    on_finished:wait()

    assert.equal(want, got)
  end)

  it("skips catch()", function()
    local want = "ok"
    local got
    local called = false
    local on_finished = helper.on_finished()
    Promise.new(function(resolve)
      resolve(want)
    end):catch(function()
      called = true
    end):next(function(v)
      got = v
      on_finished()
    end)
    on_finished:wait()

    assert.is_false(called)
    assert.equal(want, got)
  end)

  it("can chain with promise", function()
    local want = "ok"
    local got
    local on_finished = helper.on_finished()
    Promise.new(function(resolve)
      resolve(want)
    end):next(function(v)
      return Promise.new(function(resolve)
        resolve(v)
      end)
    end):next(function(v)
      got = v
      on_finished()
    end)
    on_finished:wait()

    assert.equal(want, got)
  end)

  it("can chain to promises", function()
    local want = "ok"

    local promise = Promise.new(function(resolve)
      resolve(want)
    end)

    local on_finished1 = helper.on_finished()
    local on_finished2 = helper.on_finished()
    local got1, got2
    promise:next(function(v)
      got1 = v
      on_finished1()
    end)
    promise:next(function(v)
      got2 = v
      on_finished2()
    end)
    on_finished1:wait()
    on_finished2:wait()

    assert.equal(want, got1)
    assert.equal(want, got2)
  end)

  it("can chain with timered promise", function()
    local want = "ok"
    local got
    local on_finished = helper.on_finished()
    Promise.new(function(resolve)
      vim.defer_fn(function()
        resolve(want)
      end, 25)
    end):next(function(v)
      return Promise.new(function(resolve)
        vim.defer_fn(function()
          local want2 = v .. "2"
          resolve(want2)
        end, 25)
      end)
    end):next(function(v)
      got = v
      on_finished()
    end)
    on_finished:wait()

    assert.equal(want .. "2", got)
  end)

end)

describe("promise:catch()", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can chain with non-promise", function()
    local want = "error"
    local got
    local on_finished = helper.on_finished()
    Promise.new(function(_, reject)
      reject(want)
    end):catch(function(err)
      got = err
      on_finished()
    end)
    on_finished:wait()

    assert.equal(want, got)
  end)

  it("skips next()", function()
    local want = "error"
    local got
    local called = false
    local on_finished = helper.on_finished()
    Promise.new(function(_, reject)
      reject(want)
    end):next(function()
      called = true
    end):catch(function(err)
      got = err
      on_finished()
    end)
    on_finished:wait()

    assert.is_false(called)
    assert.equal(want, got)
  end)

  it("can chain with promise", function()
    local want = "error"
    local got
    local on_finished = helper.on_finished()
    Promise.new(function(_, reject)
      reject(want)
    end):catch(function(v)
      return Promise.new(function(_, reject)
        reject(v)
      end)
    end):catch(function(v)
      got = v
      on_finished()
    end)
    on_finished:wait()

    assert.equal(want, got)
  end)

  it("can chain to promises", function()
    local want = "error"

    local promise = Promise.new(function(_, reject)
      reject(want)
    end)

    local on_finished1 = helper.on_finished()
    local on_finished2 = helper.on_finished()
    local got1, got2
    promise:catch(function(v)
      got1 = v
      on_finished1()
    end)
    promise:catch(function(v)
      got2 = v
      on_finished2()
    end)
    on_finished1:wait()
    on_finished2:wait()

    assert.equal(want, got1)
    assert.equal(want, got2)
  end)

  it("catches error() in next()", function()
    local want = "error"
    local got
    local on_finished = helper.on_finished()
    Promise.new(function(resolve)
      resolve(want)
    end):next(function(v)
      error(v, 0) -- 0 not to add error position to message
    end):catch(function(err)
      got = err
      on_finished()
    end)
    on_finished:wait()

    assert.equal(want, got)
  end)

  it("can chain with timered promise", function()
    local want = "error"
    local got
    local on_finished = helper.on_finished()
    Promise.new(function(resolve)
      resolve("ok")
    end):next(function()
      return Promise.new(function(_, reject)
        vim.defer_fn(function()
          reject(want)
        end, 25)
      end)
    end):catch(function(v)
      got = v
      on_finished()
    end)
    on_finished:wait()

    assert.equal(want, got)
  end)

end)

describe("promise:finally()", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("continues from next()", function()
    local called = false
    local on_finished = helper.on_finished()
    Promise.new(function(resolve)
      resolve("ok")
    end):next(function(v)
      return v
    end):finally(function()
      called = true
      on_finished()
    end)
    on_finished:wait()

    assert.is_true(called)
  end)

  it("passes value to next()", function()
    local want = "ok"
    local got
    local on_finished = helper.on_finished()
    Promise.new(function(resolve)
      resolve(want)
    end):next(function(v)
      return v
    end):finally(function()
      -- noop
    end):next(function(v)
      got = v
      on_finished()
    end)
    on_finished:wait()

    assert.is_same(want, got)
  end)

  it("continues from catch()", function()
    local called = false
    local on_finished = helper.on_finished()
    Promise.new(function(_, reject)
      reject("error")
    end):catch(function(err)
      error(err)
    end):finally(function()
      called = true
      on_finished()
    end)
    on_finished:wait()

    assert.is_true(called)
  end)

  it("passes err to catch()", function()
    local want = "error"
    local got
    local on_finished = helper.on_finished()
    Promise.new(function(_, reject)
      reject(want)
    end):catch(function(err)
      error(err, 0)
    end):finally(function()
      -- noop
    end):catch(function(err)
      got = err
      on_finished()
    end)
    on_finished:wait()

    assert.is_same(want, got)
  end)

end)

-- TODO test
