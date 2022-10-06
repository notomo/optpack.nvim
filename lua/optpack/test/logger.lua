local pathlib = require("optpack.lib.path")
local path = pathlib.join(vim.fn.stdpath("cache"), "optpack", "test.log")
vim.fn.mkdir(pathlib.dir(path), "p")
local file = io.open(path, "a+")
file:write("\n")
file:close()
return {
  logger = require("optpack.lib.logger").Logger.new(require("optpack.lib.logger").file_output(path)),
  path = path,
}
