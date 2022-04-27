local Plugin = require("optpack.core.plugin").Plugin

local Plugins = {}
Plugins.__index = Plugins

function Plugins.new()
  local tbl = {
    _plugins = require("optpack.core.plugin_collection").new(),
    _loaders = require("optpack.core.loaders").new(),
  }
  return setmetatable(tbl, Plugins)
end

local _state = Plugins.new()
function Plugins.state()
  return _state
end

function Plugins.add(self, full_name, opts)
  local plugin, err = Plugin.new(full_name, opts)
  if err then
    return ("%s: %s"):format(full_name, err)
  end

  if not opts.enabled then
    self._plugins:remove(plugin.name)
    self._loaders:remove(plugin.name)
    return
  end

  self._plugins:add(plugin)

  local loader_err = self._loaders:add(plugin, opts)
  if loader_err then
    return ("%s: %s"):format(plugin.name, loader_err)
  end

  local ok, hook_err = pcall(opts.hooks.post_add, plugin:expose())
  if not ok then
    return ("%s: post_add: %s"):format(plugin.name, hook_err)
  end
end

function Plugins.expose(self)
  return self._plugins:expose()
end

function Plugins.expose_one(self, plugin_name)
  vim.validate({ plugin_name = { plugin_name, "string" } })
  local plugin = self._plugins:find_by_name(plugin_name)
  if not plugin then
    return nil, "not found plugin: " .. plugin_name
  end
  return plugin:expose()
end

function Plugins.install_or_update(self, cmd_type, emitter, pattern, parallel_opts, on_finished)
  local Event = require("optpack.core.event").specific(cmd_type)

  emitter:emit(Event.Start)

  local raw_plugins = self._plugins:collect(pattern)
  local counter = require("optpack.lib.counter").new(#raw_plugins, function(finished_count, all_count)
    emitter:emit(Event.Progressed, finished_count, all_count)
  end)

  local parallel = require("optpack.lib.parallel_limitter").new(parallel_opts.limit)
  local names = {}
  for _, plugin in ipairs(raw_plugins) do
    parallel:add(function()
      local plugin_emitter = emitter:with({ name = plugin.name })
      return plugin[cmd_type](plugin, plugin_emitter)
        :next(function(installed_now)
          if installed_now then
            table.insert(names, plugin.name)
          end
        end)
        :catch(function(err)
          plugin_emitter:emit(Event.Error, err)
        end)
        :finally(function()
          counter = counter:increment()
        end)
    end)
  end

  parallel
    :start()
    :finally(function()
      local err = self._loaders:load_installed(self._plugins:from(names))
      if err then
        emitter:emit(Event.Error, err)
      end
      emitter:emit(Event.Finished)
      on_finished()
    end)
    :catch(function(err)
      emitter:emit(Event.Error, err)
    end)
end

function Plugins.load(self, plugin_name)
  local plugin = self._plugins:find_by_name(plugin_name)
  if not plugin then
    return "not found plugin: " .. plugin_name
  end

  for _, depend in ipairs(plugin.depends) do
    local err = self:load(depend)
    if err then
      return plugin_name .. " depends: " .. err
    end
  end

  return self._loaders:load(plugin)
end

return Plugins
