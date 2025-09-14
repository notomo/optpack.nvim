local Git = {}

function Git.clone(directory, url, depth)
  local cmd = {
    "git",
    "clone",
    "--origin",
    "origin",
    "--no-single-branch",
  }
  if depth > 0 then
    vim.list_extend(cmd, { "--depth", depth })
  end
  vim.list_extend(cmd, { "--", url .. ".git", directory })
  return Git._start(cmd)
end

function Git.fetch(directory)
  local cmd = {
    "git",
    "--git-dir",
    vim.fs.joinpath(directory, ".git"),
    "fetch",
    "--quiet",
    "--tags",
    "--force",
    "origin",
  }
  return Git._start(cmd, { cwd = directory })
end

function Git._pull(directory)
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

function Git._switch_with_tracking(directory, revision, remote)
  return Git._exists_local_branch(directory, revision):next(function(exists)
    if exists then
      return Git._checkout(directory, revision)
    end
    local cmd = {
      "git",
      "--git-dir",
      vim.fs.joinpath(directory, ".git"),
      "switch",
      "-c",
      revision,
      "--track",
      remote,
    }
    return Git._start(cmd, { cwd = directory })
  end)
end

function Git._checkout(directory, revision)
  local cmd = {
    "git",
    "--git-dir",
    vim.fs.joinpath(directory, ".git"),
    "checkout",
    "--quiet",
    revision,
  }
  return Git._start(cmd, { cwd = directory })
end

function Git._exists_local_branch(directory, name)
  local cmd = {
    "git",
    "--git-dir",
    vim.fs.joinpath(directory, ".git"),
    "rev-parse",
    "--verify",
    "--quiet",
    name,
  }
  return Git._start(cmd, { cwd = directory })
    :next(function()
      return true
    end)
    :catch(function()
      return false
    end)
end

function Git.update(directory, version)
  if not version then
    return Git._get_default_branch(directory)
      :next(function(remote_branch)
        local branch = vim.split(remote_branch, "origin/", { plain = true })[2]
        return Git._switch_with_tracking(directory, branch, remote_branch)
      end)
      :next(function()
        return Git._pull(directory)
      end)
  end

  return Git._switch_with_tracking(directory, version, "origin/" .. version):next(function()
    return Git._pull(directory)
  end)
end

function Git._get_default_branch(directory)
  local cmd = { "git", "--git-dir", vim.fs.joinpath(directory, ".git"), "rev-parse", "--abbrev-ref", "origin/HEAD" }
  return Git._start(cmd, {
    cwd = directory,
    handle_stdout = function(stdout)
      return stdout
    end,
  })
end

function Git.get_revision(directory, version)
  local cmd = { "git", "--git-dir", vim.fs.joinpath(directory, ".git"), "rev-list", "-1", "--abbrev-commit", version }
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
