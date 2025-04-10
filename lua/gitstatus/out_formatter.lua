local parser = require('gitstatus.parser')

local M = {}

---@class Line
---@field str string
---@field highlight_group string
---@field file File?
Line = {}

---@param file_edit_type FILE_EDIT_TYPE
---@return string
local function prefix(file_edit_type)
  return file_edit_type == FILE_EDIT_TYPE.modified and 'modified: '
      or file_edit_type == FILE_EDIT_TYPE.new and 'new file: '
      or file_edit_type == FILE_EDIT_TYPE.deleted and 'deleted: '
      or file_edit_type == FILE_EDIT_TYPE.renamed and 'renamed: '
      or ''
end

---@param file_state FILE_STATE
---@return string
local function get_highlight_group(file_state)
  return file_state == FILE_STATE.staged and 'staged' or 'not_staged'
end

---@param files File[]
---@return File[], File[], File[]
local function split_files_by_state(files)
  local staged = {}
  local not_staged = {}
  local untracked  = {}
  for _, file in ipairs(files) do
    if file.state == FILE_STATE.staged then
      table.insert(staged, file)
    elseif file.state == FILE_STATE.not_staged then
      table.insert(not_staged, file)
    elseif file.state == FILE_STATE.untracked then
      table.insert(untracked, file)
    end
  end
  return staged, not_staged, untracked
end

---@param files File[]
---@return Line[], string?
function M.get_lines(files)
  local lines = {}

  local branch, err = parser.branch()
  if err ~= nil then
    return {}, err
  else
    table.insert(lines, {
      str = "Branch: " .. branch,
      highlight_group = nil,
      file = nil,
    })
  end

  if #files == 0 then
    if #lines > 0 then
      table.insert(lines, { str = "", highlight_group = nil, file = nil, })
    end
    table.insert(lines, {
      str = "nothing to commit, working tree clean",
      highlight_group = nil,
      file = nil,
    })
    return lines, nil
  end

  local staged, not_staged, untracked = split_files_by_state(files)
  local file_table = { staged, not_staged, untracked }
  local name = function(i)
    return i == 1 and "Staged:" or i == 2 and "Not staged:" or "Untracked:"
  end
  for i, files_of_type in ipairs(file_table) do
    if #files_of_type > 0 then
      if #lines > 0 then
        table.insert(lines, { str = "", highlight_group = nil, file = nil, })
      end
      table.insert(lines, { str = name(i), highlight_group = nil, file = nil, })
    end
    for _, file in ipairs(files_of_type) do
      local line = {
        str = prefix(file.type) .. file.name,
        highlight_group = get_highlight_group(file.state),
        file = file,
      }
      table.insert(lines, line)
    end
  end
  table.insert(lines, { str = "", highlight_group = nil, file = nil, })
  table.insert(lines, {
    str = "s = stage/unstage, c = commit, q = quit, a = stage all",
    highlight_group = nil,
    file = nil,
  })
  return lines
end

return M
