local StringUtils = require('gitstatus.string_utils')

local M = {}

---@return string, string?
function M.status()
  local obj = vim
    .system({ 'git', 'status', '--porcelain=v1' }, { text = true })
    :wait()
  if obj.code ~= 0 then
    return '', 'Unable to get git status: ' .. obj.stderr
  end
  return obj.stdout, nil
end

---@return string, string?
function M.branch()
  local obj = vim.system({ 'git', 'branch' }, { text = true }):wait()
  if obj.code ~= 0 then
    return '', 'Unable to get git branch: ' .. obj.stderr
  end
  return obj.stdout, nil
end

---@param file string
---@param cwd string
---@return string?
function M.stage_file(file, cwd)
  local obj = vim
    .system({ 'git', 'add', file }, { text = true, cwd = cwd })
    :wait()
  if obj.code ~= 0 then
    return 'Unable to stage file: ' .. obj.stderr
  end
end

---@param file string
---@param cwd string
---@return string?
function M.unstage_modified_file(file, cwd)
  local obj = vim
    .system({ 'git', 'restore', '--staged', file }, { text = true, cwd = cwd })
    :wait()
  if obj.code ~= 0 then
    return 'Unable to unstage file: ' .. obj.stderr
  end
end

---@param file string
---@param cwd string
---@return string?
function M.unstage_added_file(file, cwd)
  local obj = vim
    .system({ 'git', 'rm', '--cached', file }, { text = true, cwd = cwd })
    :wait()
  if obj.code ~= 0 then
    return 'Unable to unstage file: ' .. obj.stderr
  end
end

---@return string?
function M.stage_all()
  local obj = vim.system({ 'git', 'add', '-A' }, { text = true }):wait()
  if obj.code ~= 0 then
    return 'Unable to stage all changes: ' .. obj.stderr
  end
end

---@param filename string
---@return string, string? # success message, error
function M.commit(filename)
  local obj = vim
    .system({ 'git', 'commit', '-F', filename }, { text = true })
    :wait()
  if obj.code ~= 0 then
    return '', obj.stderr
  else
    return obj.stdout, nil
  end
end

---@return string, string?
function M.repo_root_dir()
  local obj = vim
    .system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true })
    :wait()
  if obj.code ~= 0 then
    return '', 'Unable to get git repo root dir: ' .. obj.stderr
  end
  return StringUtils.strip_trailing_newline(obj.stdout), nil
end

---@param repo_root string
---@return boolean
function M.repo_has_pre_commit_hook(repo_root)
  local obj = vim
    .system({ 'test', '-e', '.git/hooks/pre-commit' }, { cwd = repo_root })
    :wait()
  return obj.code == 0
end

return M
