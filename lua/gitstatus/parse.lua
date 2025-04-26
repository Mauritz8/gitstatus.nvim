local Path = require('gitstatus.path')

local M = {}

---@param str string
---@param delim string
---@return string[]
local function split(str, delim)
  if #str == 0 then
    return {}
  end

  local matches = {}
  local match_start = 1
  while true do
    local delim_start, delim_end = str:find(delim, match_start)
    if delim_start ~= nil and delim_end ~= nil then
      table.insert(matches, str:sub(match_start, delim_start - 1))
      match_start = delim_end + 1
    else
      local remaining_str = str:sub(match_start)
      if #remaining_str > 0 then
        table.insert(matches, remaining_str)
      end
      break
    end
  end
  return matches
end

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

---@param line string
---@return Path
local function line_to_path(line)
  -- TODO: what if filename is empty
  local path = line:sub(4)
  local orig_path = nil
  if path:find(' %-> ') then
    local paths = split(path, ' %-> ')
    -- TODO: what if filename contains ' -> '
    assert(#paths == 2)
    path = paths[2]
    orig_path = paths[1]
  end

  if path:sub(1, 1) == '"' and path:sub(-1, -1) == '"' then
    path = path:sub(2, -2)
  end
  if
    orig_path
    and orig_path:sub(1, 1) == '"'
    and orig_path:sub(-1, -1) == '"'
  then
    orig_path = orig_path:sub(2, -2)
  end

  return {
    path = path,
    orig_path = orig_path,
    x = str_to_status(line:sub(1, 1)),
    y = str_to_status(line:sub(2, 2)),
    untracked = line:sub(1, 2) == '??',
  }
end

---@param status_output string
---@return Path[]
function M.git_status(status_output)
  local lines = split(status_output, '\n')

  ---@type Path[]
  local paths = {}
  for _, line in ipairs(lines) do
    local path = line_to_path(line)
    table.insert(paths, path)
  end
  return paths
end

---@param branch_output string
---@return string
function M.git_branch(branch_output)
  local branch, _ = branch_output:gsub('\n', '')
  return branch
end

return M
