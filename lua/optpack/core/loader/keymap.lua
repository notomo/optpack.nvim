local OnKeymaps = {}
OnKeymaps.__index = OnKeymaps

function OnKeymaps.set(plugin_name, set_keymaps)
  local set = function(mode, lhs, rhs, opts)
    if type(rhs) == "function" then
      return vim.keymap.set(mode, lhs, function()
        require("optpack").load(plugin_name)
        return rhs()
      end, opts)
    end

    opts = opts or {}
    opts.expr = true
    vim.keymap.set(mode, lhs, function()
      require("optpack").load(plugin_name)
      return rhs
    end, opts)
  end

  local original_vim = vim
  local keymap = setmetatable({ set = set }, {
    __index = function(_, k)
      return original_vim.keymap[k]
    end,
  })
  local vim = setmetatable({ keymap = keymap }, {
    __index = function(_, k)
      return original_vim[k]
    end,
  })

  local ok, err = pcall(set_keymaps, vim)
  if not ok then
    return nil, ("load_on.keymaps: %s"):format(err)
  end

  return function()
    set_keymaps(original_vim)
  end, nil
end

return OnKeymaps
