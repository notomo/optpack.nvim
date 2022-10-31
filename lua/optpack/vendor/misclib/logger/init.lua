local Logger = {}
Logger.__index = Logger

Logger.levels = vim.deepcopy(vim.log.levels)
Logger._prefixes = {
  [Logger.levels.DEBUG] = "DEBUG",
  [Logger.levels.INFO] = "INFO",
  [Logger.levels.WARN] = "WARN",
  [Logger.levels.ERROR] = "ERROR",
}

function Logger.new(output, opts)
  vim.validate({ output = { output, "function" }, opts = { opts, "table", true } })
  opts = opts or {}
  opts.level = opts.level or Logger.levels.INFO
  opts.prefix = opts.prefix or ""
  local tbl = {
    _level = opts.level,
    _output = output,
    _prefix = opts.prefix,
  }
  return setmetatable(tbl, Logger)
end

function Logger.debug(self, msg)
  self:log(Logger.levels.DEBUG, msg)
end

function Logger.info(self, msg)
  self:log(Logger.levels.INFO, msg)
end

function Logger.warn(self, msg)
  self:log(Logger.levels.WARN, msg)
end

function Logger.error(self, msg)
  self:log(Logger.levels.ERROR, msg)
end

function Logger.log(self, level, msg)
  if level < self._level then
    return
  end
  local level_prefix = ("[%s] "):format(Logger._prefixes[level])
  self._output(self._prefix .. level_prefix .. msg .. "\n")
end

function Logger.add_prefix(self, prefix)
  vim.validate({ prefix = { prefix, "string" } })
  return Logger.new(self._output, { level = self._level, prefix = self._prefix .. prefix })
end

return Logger
