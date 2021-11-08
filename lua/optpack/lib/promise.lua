local vim = vim

local M = {}

local PromiseStatus = {Pending = "Pending", Fulfilled = "Fulfilled", Rejected = "Rejected"}

local Promise = {}
Promise.__index = Promise
M.Promise = Promise

function Promise._new_pending(f)
  vim.validate({f = {f, "function", true}})
  local tbl = {
    _status = PromiseStatus.Pending,
    _next_promises = {},
    _catch_promises = {},
    _finally_promises = {},
    _value = nil,
    _f = f or function(...)
      return ...
    end,
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

function Promise.is_promise(v)
  return getmetatable(v) == Promise
end

function Promise.resolve(v)
  if Promise.is_promise(v) then
    return v
  end
  return Promise.new(function(resolve, _)
    resolve(v)
  end)
end

function Promise.reject(v)
  if Promise.is_promise(v) then
    return v
  end
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
  for _, promise in ipairs(self._next_promises) do
    promise:_start_resolve(resolved)
  end
  for _, promise in ipairs(self._catch_promises) do
    promise:_resolve(resolved)
  end
  for _, promise in ipairs(self._finally_promises) do
    promise:_start_resolve_finally(resolved)
  end
end

function Promise._start_resolve(self, v)
  local ok, result = pcall(self._f, v)
  if not ok then
    return self:_reject(result)
  end
  if not Promise.is_promise(result) then
    return self:_resolve(result)
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
  for _, promise in ipairs(self._catch_promises) do
    promise:_start_reject(rejected)
  end
  for _, promise in ipairs(self._next_promises) do
    promise:_reject(rejected)
  end
  for _, promise in ipairs(self._finally_promises) do
    promise:_start_reject_finally(rejected)
  end
end

function Promise._start_reject(self, v)
  local ok, result = pcall(self._f, v)
  if ok and not Promise.is_promise(result) then
    return self:_resolve(result)
  end
  if not Promise.is_promise(result) then
    return self:_reject(result)
  end
  result:next(function(...)
    self:_resolve(...)
  end):catch(function(...)
    self:_reject(...)
  end)
end

-- TODO: promise
function Promise._start_resolve_finally(self, v)
  if self._status ~= PromiseStatus.Pending then
    return
  end
  local ok, result = pcall(self._f)
  if ok then
    if not Promise.is_promise(result) then
      return self:_resolve(v)
    end
    return result:next(function(...)
      self:_resolve(...)
    end)
  end
  if not Promise.is_promise(result) then
    return self:_reject(result)
  end
  result:catch(function(...)
    self:_reject(...)
  end)
end

-- TODO: promise
function Promise._start_reject_finally(self, rejected)
  if self._status ~= PromiseStatus.Pending then
    return
  end
  local ok, result = pcall(self._f)
  if ok then
    if not Promise.is_promise(result) then
      return self:_reject(rejected)
    end
    return result:catch(function(...)
      self:_reject(...)
    end)
  end
  if not Promise.is_promise(result) then
    return self:_reject(result)
  end
  result:catch(function(...)
    self:_reject(...)
  end)
end

function Promise.next(self, f)
  vim.validate({f = {f, "function"}})

  if self._status == PromiseStatus.Fulfilled then
    local promise = Promise._new_pending(f)
    promise:_start_resolve(self._value)
    return promise
  end

  if self._status == PromiseStatus.Rejected then
    return Promise.reject(self._value)
  end

  local promise = Promise._new_pending(f)
  table.insert(self._next_promises, promise)
  return promise
end

function Promise.catch(self, f)
  vim.validate({f = {f, "function"}})

  if self._status == PromiseStatus.Fulfilled then
    return Promise.resolve(self._value)
  end

  if self._status == PromiseStatus.Rejected then
    local promise = Promise._new_pending(f)
    promise:_start_reject(self._value)
    return promise
  end

  local promise = Promise._new_pending(f)
  table.insert(self._catch_promises, promise)
  return promise
end

function Promise.finally(self, f)
  vim.validate({f = {f, "function"}})

  if self._status == PromiseStatus.Fulfilled then
    local promise = Promise._new_pending(f)
    promise:_start_resolve_finally(self._value)
    return promise
  end

  if self._status == PromiseStatus.Rejected then
    local promise = Promise._new_pending(f)
    promise:_start_reject_finally(self._value)
    return promise
  end

  local promise = Promise._new_pending(f)
  table.insert(self._finally_promises, promise)
  return promise
end

function Promise.is_pending(self)
  return self._status == PromiseStatus.Pending
end

return M
