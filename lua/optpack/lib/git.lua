local Git = {}

--- @async
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

--- @async
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

--- @async
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

--- @async
function Git._switch_with_tracking(directory, revision, remote)
  if Git._exists_local_branch(directory, revision) then
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
end

--- @async
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

--- @async
--- @return boolean
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
  local exists = pcall(Git._start, cmd, { cwd = directory })
  return exists
end

--- @async
function Git.update(directory, version)
  if not version then
    local remote_branch = Git._get_default_branch(directory)
    local branch = vim.split(remote_branch, "origin/", { plain = true })[2]
    Git._switch_with_tracking(directory, branch, remote_branch)
    return Git._pull(directory)
  end

  Git._switch_with_tracking(directory, version, "origin/" .. version)
  return Git._pull(directory)
end

--- @async
--- @return string
function Git._get_default_branch(directory)
  local cmd = { "git", "--git-dir", vim.fs.joinpath(directory, ".git"), "rev-parse", "--abbrev-ref", "origin/HEAD" }
  return Git._start(cmd, {
    cwd = directory,
    handle_stdout = function(stdout)
      return stdout
    end,
  })
end

--- @async
--- @return string
function Git.get_revision(directory, version)
  local cmd = { "git", "--git-dir", vim.fs.joinpath(directory, ".git"), "rev-list", "-1", "--abbrev-commit", version }
  return Git._start(cmd, {
    cwd = directory,
    handle_stdout = function(stdout)
      return stdout
    end,
  })
end

--- @async
function Git.log(directory, target_revision)
  local cmd = {
    "git",
    "--git-dir",
    vim.fs.joinpath(directory, ".git"),
    "log",
    [[--pretty=format:%h %s]],
    target_revision,
  }
  local outputs = Git._start(cmd, { cwd = directory })
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
end

--- @async
--- @return any # opts.handle_stdout applied to the stdout
function Git._start(cmd, opts)
  opts = opts or {}
  opts.handle_stdout = opts.handle_stdout or function(stdout)
    return vim.split(stdout, "\n", { plain = true })
  end

  --- @type vim.SystemCompleted?
  local completed
  local start_err
  vim.async.await(function(callback)
    -- WHY: without schedule_wrap the task resumes in a fast event context and
    -- any vim.api call after this await fails with E5560
    -- NOT: passing the callback to vim.system as it is
    local ok, err = pcall(
      vim.system,
      cmd,
      {
        text = true,
        cwd = opts.cwd,
      },
      vim.schedule_wrap(function(o)
        completed = o
        callback()
      end)
    )
    if not ok then
      start_err = err
      callback()
    end
  end)

  if start_err then
    error(start_err, 0)
  end

  local o = assert(completed)
  if o.code ~= 0 then
    error({ table.concat(cmd, " "), unpack(vim.split(vim.trim(o.stderr or ""), "\n", { plain = true })) }, 0)
  end
  return opts.handle_stdout(vim.trim(o.stdout or ""))
end

return Git
