local vim = vim

local M = {}

local PromiseStatus = {Pending = "Pending", Fulfilled = "Fulfilled", Rejected = "Rejected"}

local Promise = {}
Promise.__index = Promise
M.Promise = Promise

function Promise._new_pending(on_fullfilled, on_rejected)
  vim.validate({
    on_fullfilled = {on_fullfilled, "function", true},
    on_rejected = {on_rejected, "function", true},
  })
  local tbl = {
    _status = PromiseStatus.Pending,
    _queued = {},
    _value = nil,
    _on_fullfilled = on_fullfilled,
    _on_rejected = on_rejected,
  }
  return setmetatable(tbl, Promise)
end

function Promise.new(f)
  vim.validate({f = {f, "function"}})

  local self = Promise._new_pending()

  local resolve = function(...)
    self:_resolve(...)
  end
  local reject = function(...)
    self:_reject(...)
  end
  f(resolve, reject)

  return self
end

function Promise._is_promise(v)
  return getmetatable(v) == Promise
end

function Promise.resolve(v)
  return Promise.new(function(resolve, _)
    resolve(v)
  end)
end

function Promise.reject(v)
  return Promise.new(function(_, reject)
    reject(v)
  end)
end

function Promise._resolve(self, resolved)
  if self._status ~= PromiseStatus.Pending then
    return
  end
  self._status = PromiseStatus.Fulfilled
  self._value = resolved
  for _ = 1, #self._queued do
    local promise = table.remove(self._queued, 1)
    promise:_start_resolve(resolved)
  end
end

function Promise._start_resolve(self, v)
  if not self._on_fullfilled then
    return self:_resolve(v)
  end
  local ok, result = pcall(self._on_fullfilled, v)
  if not ok then
    vim.schedule(function()
      self:_reject(result)
    end)
    return
  end
  if not Promise._is_promise(result) then
    vim.schedule(function()
      self:_resolve(result)
    end)
    return
  end
  result:next(function(...)
    self:_resolve(...)
  end):catch(function(...)
    self:_reject(...)
  end)
end

function Promise._reject(self, rejected)
  if self._status ~= PromiseStatus.Pending then
    return
  end
  self._status = PromiseStatus.Rejected
  self._value = rejected
  for _ = 1, #self._queued do
    local promise = table.remove(self._queued, 1)
    promise:_start_reject(rejected)
  end
end

function Promise._start_reject(self, v)
  if not self._on_rejected then
    return self:_reject(v)
  end
  local ok, result = pcall(self._on_rejected, v)
  if ok and not Promise._is_promise(result) then
    vim.schedule(function()
      self:_resolve(result)
    end)
    return
  end
  if not Promise._is_promise(result) then
    vim.schedule(function()
      self:_reject(result)
    end)
    return
  end
  result:next(function(...)
    self:_resolve(...)
  end):catch(function(...)
    self:_reject(...)
  end)
end

-- TODO: detect unhandled rejection
function Promise.next(self, on_fullfilled, on_rejected)
  vim.validate({
    on_fullfilled = {on_fullfilled, "function", true},
    on_rejected = {on_rejected, "function", true},
  })
  local promise = Promise._new_pending(on_fullfilled, on_rejected)
  vim.schedule(function()
    if self._status == PromiseStatus.Fulfilled then
      return promise:_start_resolve(self._value)
    end
    if self._status == PromiseStatus.Rejected then
      return promise:_start_reject(self._value)
    end
    table.insert(self._queued, promise)
  end)
  return promise
end

function Promise.catch(self, on_rejected)
  return self:next(nil, on_rejected)
end

function Promise.finally(self, on_finally)
  return self:next(function(...)
    on_finally()
    return ...
  end):catch(function(err)
    on_finally()
    error(err, 0)
  end)
end

return M
