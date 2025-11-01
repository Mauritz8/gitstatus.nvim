local Path = require('gitstatus.path')
local StringUtils = require('gitstatus.string_utils')

local M = {}

---@param str string
---@return STATUS?
local function str_to_status(str)
  return str == ' ' and Path.STATUS.unmodified
    or str == 'M' and Path.STATUS.modified
    or str == 'T' and Path.STATUS.file_type_changed
    or str == 'A' and Path.STATUS.added
    or str == 'D' and Path.STATUS.deleted
    or str == 'R' and Path.STATUS.renamed
    or str == 'C' and Path.STATUS.copied
    or str == 'U' and Path.STATUS.updated_but_unmerged
    or nil
end

---@param path_str string
---@return string, string? #path, orig_path
local function parse_line_path(path_str)
  local path1 = ''
  local path2 = ''
  local on_path1 = true
  local inside_quote = false
  local i = 1
  while i <= #path_str do
    local ch = path_str:sub(i, i)
    if ch == '"' and path_str:sub(i - 1, i) ~= '\\"' then
      inside_quote = not inside_quote
    elseif path_str:sub(i, i + 3) == ' -> ' and not inside_quote then
      on_path1 = false
      i = i + 3
    else
      if on_path1 then
        path1 = path1 .. ch
      else
        path2 = path2 .. ch
      end
    end
    i = i + 1
  end

  if path2 ~= '' then
    return path2, path1
  else
    return path1, nil
  end
end

---@param line string
---@return Path
local function line_to_path(line)
  local path, orig_path = parse_line_path(line:sub(4))

  ---@type StatusCode?
  local status_code = nil
  if line:sub(1, 2) ~= '??' then
    local x = str_to_status(line:sub(1, 1))
    local y = str_to_status(line:sub(2, 2))
    assert(x ~= nil)
    assert(y ~= nil)
    status_code = {
      x = x,
      y = y,
    }
  end

  local unmerged = line:sub(1, 2) == 'DD'
    or line:sub(1, 2) == 'AU'
    or line:sub(1, 2) == 'UD'
    or line:sub(1, 2) == 'UA'
    or line:sub(1, 2) == 'DU'
    or line:sub(1, 2) == 'AA'
    or line:sub(1, 2) == 'UU'
    or false

  ---@type Path
  return {
    path = path,
    orig_path = orig_path,
    status_code = status_code,
    unmerged = unmerged,
  }
end

---@param status_output string
---@return Path[]
function M.git_status(status_output)
  local lines = StringUtils.split(status_output, '\n')

  ---@type Path[]
  local paths = {}
  for _, line in ipairs(lines) do
    local path = line_to_path(line)
    table.insert(paths, path)
  end
  return paths
end

---@param branch_output string
---@return string, string?
function M.git_branch(branch_output)
  local lines = StringUtils.split(branch_output, '\n')
  for _, line in ipairs(lines) do
    if line:sub(1, 1) == '*' then
      return line:sub(3)
    end
  end
  return '', 'Unable to retrieve the current branch'
end

---@param git_repo_root_dir_output string
---@return string
function M.git_repo_root_dir(git_repo_root_dir_output)
  local git_repo_root_dir, _ = git_repo_root_dir_output:gsub('\n', '')
  return git_repo_root_dir
end

return M
