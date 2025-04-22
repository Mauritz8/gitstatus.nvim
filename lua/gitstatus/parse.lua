local File = require('gitstatus.file')

local M = {}

---@param str string
---@param delim string
---@return string[]
local function split(str, delim)
  local lines = {}
  for line in str:gmatch('[^' .. delim .. ']+') do
    table.insert(lines, line)
  end
  return lines
end

---@param str string
---@return FILE_EDIT_TYPE
local function str_to_file_type(str)
  return str == 'M' and File.FILE_EDIT_TYPE.modified
    or str == 'A' and File.FILE_EDIT_TYPE.new
    or str == 'D' and File.FILE_EDIT_TYPE.deleted
    or str == 'R' and File.FILE_EDIT_TYPE.renamed
    or str == 'T' and File.FILE_EDIT_TYPE.file_type_changed
    or str == 'C' and File.FILE_EDIT_TYPE.copied
    or File.FILE_EDIT_TYPE.none
end

---@param line string
---@return File[]
local function line_to_files(line)
  local name = line:sub(4)

  if line:sub(1, 2) == '??' then
    return {
      {
        name = name,
        state = File.FILE_STATE.untracked,
        type = File.FILE_EDIT_TYPE.none,
      },
    }
  end

  local files = {}

  local staged_file_type = line:sub(1, 1)
  if staged_file_type ~= ' ' then
    local file = {
      name = name,
      state = File.FILE_STATE.staged,
      type = str_to_file_type(staged_file_type),
    }
    table.insert(files, file)
  end

  local unstaged_file_type = line:sub(2, 2)
  if unstaged_file_type ~= ' ' then
    local file = {
      name = name,
      state = File.FILE_STATE.not_staged,
      type = str_to_file_type(unstaged_file_type),
    }
    table.insert(files, file)
  end

  return files
end

---@param status_output string
---@return File[]
function M.git_status(status_output)
  local lines = split(status_output, '\n')
  local files = {}
  for _, line in ipairs(lines) do
    local line_files = line_to_files(line)
    for _, file in ipairs(line_files) do
      table.insert(files, file)
    end
  end
  return files
end

---@param branch_output string
---@return string
function M.git_branch(branch_output)
  local branch, _ = branch_output:gsub('\n', '')
  return branch
end

---@param renamed_file_name string
---@return string, string, string? # old name, new name, error
function M.git_renamed_file(renamed_file_name)
  local names = split(renamed_file_name, ' %-> ')
  if #names ~= 2 then
    return '', '', 'could not parse file names'
  end
  return names[1], names[2], nil
end

return M
