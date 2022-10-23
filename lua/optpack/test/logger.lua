local output, _, path = require("optpack.vendor.misclib.logger.file").output("optpack/test.log")
return {
  logger = require("optpack.vendor.misclib.logger").new(output),
  path = path,
}
