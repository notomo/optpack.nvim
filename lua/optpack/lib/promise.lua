local vim = vim

local M = {}

local PromiseStatus = {Pending = "Pending", Fulfilled = "Fulfilled", Rejected = "Rejected"}

local Promise = {}
Promise.__index = Promise
M.Promise = Promise

local is_promise = function(v)
  return getmetatable(v) == Promise
end

local new_any_userdata = function()
  local userdata = vim.loop.new_async(function()
  end)
  userdata:close()
  return userdata
end

local new_pending = function(on_fullfilled, on_rejected)
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
    _handled = false,
    _unhandled_detector = new_any_userdata(),
  }
  local self = setmetatable(tbl, Promise)

  getmetatable(tbl._unhandled_detector).__gc = function()
    if self._status ~= PromiseStatus.Rejected or self._handled then
      return
    end
    vim.schedule(function()
      error("unhandled promise rejection: " .. tostring(self._value))
    end)
  end

  return self
end

function Promise.new(f)
  vim.validate({f = {f, "function"}})

  local self = new_pending()

  local resolve = function(...)
    self:_resolve(...)
  end
  local reject = function(...)
    self:_reject(...)
  end
  f(resolve, reject)

  return self
end

function Promise.resolve(v)
  if is_promise(v) then
    return v
  end
  return Promise.new(function(resolve, _)
    resolve(v)
  end)
end

function Promise.reject(v)
  if is_promise(v) then
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
  for _ = 1, #self._queued do
    local promise = table.remove(self._queued, 1)
    promise:_start_resolve(resolved)
  end
end

function Promise._start_resolve(self, resolved)
  if not self._on_fullfilled then
    return self:_resolve(resolved)
  end
  local ok, result = pcall(self._on_fullfilled, resolved)
  if not ok then
    return vim.schedule(function()
      self:_reject(result)
    end)
  end
  if not is_promise(result) then
    return vim.schedule(function()
      self:_resolve(result)
    end)
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
  local handled = self._handled
  for _ = 1, #self._queued do
    local promise = table.remove(self._queued, 1)
    promise:_start_reject(rejected)
    handled = handled or promise._on_rejected ~= nil
  end
  self._handled = handled
end

function Promise._start_reject(self, rejected)
  if not self._on_rejected then
    return self:_reject(rejected)
  end
  local ok, result = pcall(self._on_rejected, rejected)
  if ok and not is_promise(result) then
    return vim.schedule(function()
      self:_resolve(result)
    end)
  end
  if not is_promise(result) then
    return vim.schedule(function()
      self:_reject(result)
    end)
  end
  result:next(function(...)
    self:_resolve(...)
  end):catch(function(...)
    self:_reject(...)
  end)
end

function Promise.next(self, on_fullfilled, on_rejected)
  vim.validate({
    on_fullfilled = {on_fullfilled, "function", true},
    on_rejected = {on_rejected, "function", true},
  })
  local promise = new_pending(on_fullfilled, on_rejected)
  vim.schedule(function()
    if self._status == PromiseStatus.Fulfilled then
      return promise:_start_resolve(self._value)
    end
    if self._status == PromiseStatus.Rejected then
      self._handled = self._handled or on_rejected ~= nil
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
  vim.validate({on_finally = {on_finally, "function", true}})
  return self:next(function(...)
    on_finally()
    return ...
  end):catch(function(err)
    on_finally()
    error(err, 0)
  end)
end

function Promise.all(list)
  vim.validate({list = {list, "table"}})
  local remain = #list
  local results = {}
  return Promise.new(function(resolve, reject)
    if remain == 0 then
      resolve(results)
    end

    for i, e in ipairs(list) do
      Promise.resolve(e):next(function(v)
        results[i] = v
        if remain == 1 then
          return resolve(results)
        end
        remain = remain - 1
      end):catch(function(...)
        reject(...)
      end)
    end
  end)
end

function Promise.race(list)
  vim.validate({list = {list, "table"}})
  return Promise.new(function(resolve, reject)
    for _, e in ipairs(list) do
      Promise.resolve(e):next(function(...)
        return resolve(...)
      end):catch(function(...)
        reject(...)
      end)
    end
  end)
end

return M
