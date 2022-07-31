local pack_dir = vim.fn.expand("~/example-packages")
vim.opt.packpath:prepend(pack_dir)
local manager_dir = pack_dir .. "/pack/optpack/opt/optpack.nvim"
local initializing = vim.fn.isdirectory(manager_dir) ~= 1
if initializing then
  vim.cmd["!"]({ args = { "git", "clone", "https://github.com/notomo/optpack.nvim", manager_dir } })
end

local optpack = require("optpack")

-- add some plugins
optpack.add("notomo/optpack.nvim")
optpack.add("notomo/ignored", { enabled = false })
optpack.add("notomo/gesture.nvim", {
  load_on = { modules = { "gesture" } }, -- load on `require("gesture")`
  hooks = {
    post_add = function()
      -- mapping
    end,
    post_load = function()
      -- setting after loading
    end,
  },
})
optpack.add("notomo/vusted", {
  fetch = { depth = 0 }, -- fetch including history
})

if initializing then
  optpack.update()
end
