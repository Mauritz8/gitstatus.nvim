local M = {}

---@return string, string?
function M.status()
  local obj = vim.system({ 'git', 'status', '-s' }, { text = true }):wait()
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
---@return string?
function M.stage_file(file)
  local obj = vim.system({ 'git', 'add', file }, { text = true }):wait()
  if obj.code ~= 0 then
    return 'Unable to stage file: ' .. obj.stderr
  end
end

---@param file string
---@return string?
function M.unstage_file(file)
  local obj = vim
    .system({ 'git', 'restore', '--staged', file }, { text = true })
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

return M
