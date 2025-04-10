require('gitstatus.file')
local git = require('gitstatus.git')

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
  return str == 'M' and FILE_EDIT_TYPE.modified
      or str == 'A' and FILE_EDIT_TYPE.new
      or str == 'D' and FILE_EDIT_TYPE.deleted
      or str == 'R' and FILE_EDIT_TYPE.renamed
      or FILE_EDIT_TYPE.none
end

---@param line string
---@return File[]
local function line_to_files(line)
    local name = line:sub(4)

    if line:sub(1, 2) == "??" then
      return {{
        name = name,
        state = FILE_STATE.untracked,
        type = FILE_EDIT_TYPE.none,
      }}
    end

    local files = {}

    local staged_file_type = line:sub(1, 1)
    if staged_file_type ~= " " then
      local file = {
        name = name,
        state = FILE_STATE.staged,
        type = str_to_file_type(staged_file_type),
      }
      table.insert(files, file)
    end

    local unstaged_file_type = line:sub(2, 2)
    if unstaged_file_type ~= " " then
      local file = {
        name = name,
        state = FILE_STATE.not_staged,
        type = str_to_file_type(unstaged_file_type),
      }
      table.insert(files, file)
    end

    return files
end

---@param lines string[]
---@return File[]
local function lines_to_files(lines)
  local files = {}
  for _, line in ipairs(lines) do
    local line_files = line_to_files(line)
    for _, file in ipairs(line_files) do
      table.insert(files, file)
    end
  end
  return files
end

---@return File[], string?
function M.retrieve_files()
  local out, err = git.status()
  if err ~= nil then
    return {}, err
  end
  local lines = split(out, '\n')
  return lines_to_files(lines)
end

---@return string, string?
function M.branch()
  local out, err = git.branch()
  if err ~= nil then
    return "", err
  end
  local lines = split(out, '\n')
  for _, line in ipairs(lines) do
    if line:find("*", 1, true) then
      return line:sub(3), nil
    end
  end
  return "", "Unable to find current branch"
end

return M
