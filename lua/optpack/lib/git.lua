local Git = {}

function Git.clone(directory, url, depth)
  local cmd = { "git", "clone", "--no-single-branch" }
  if depth > 0 then
    vim.list_extend(cmd, { "--depth", depth })
  end
  vim.list_extend(cmd, { "--", url .. ".git", directory })
  return Git._start(cmd)
end

function Git.pull(directory)
  local cmd = {
    "git",
    "--git-dir",
    vim.fs.joinpath(directory, ".git"),
    "pull",
    "--ff-only",
    "--rebase=false",
  }
  return Git._start(cmd, { cwd = directory })
end

function Git.get_revision(directory)
  local cmd = { "git", "--git-dir", vim.fs.joinpath(directory, ".git"), "rev-parse", "--short", "HEAD" }
  return Git._start(cmd, {
    cwd = directory,
    handle_stdout = function(stdout)
      return stdout
    end,
  })
end

function Git.log(directory, target_revision)
  local cmd = {
    "git",
    "--git-dir",
    vim.fs.joinpath(directory, ".git"),
    "log",
    [[--pretty=format:%h %s]],
    target_revision,
  }
  return Git._start(cmd, { cwd = directory }):next(function(outputs)
    return vim
      .iter(outputs)
      :map(function(output)
        local index = output:find(" ")
        local revision = output:sub(1, index)
        local message = output:sub(index + 1)
        return {
          revision = revision,
          message = message,
        }
      end)
      :totable()
  end)
end

function Git._start(cmd, opts)
  opts = opts or {}
  opts.handle_stdout = opts.handle_stdout or function(stdout)
    return vim.split(stdout, "\n", { plain = true })
  end

  local promise, resolve, reject = require("optpack.vendor.promise").with_resolvers()

  local ok, err = pcall(function()
    vim.system(
      cmd,
      {
        text = true,
        cwd = opts.cwd,
      },
      vim.schedule_wrap(function(o)
        if o.code == 0 then
          return resolve(opts.handle_stdout(vim.trim(o.stdout)))
        end
        local err = { table.concat(cmd, " "), unpack(vim.split(vim.trim(o.stderr), "\n", { plain = true })) }
        return reject(err)
      end)
    )
  end)
  if not ok and err then
    reject(err)
  end

  return promise
end

return Git
