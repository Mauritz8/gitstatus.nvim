require("file")

local parser = {}

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

---@param cmd string
---@return string
local function execute_cmd(cmd)
  local handle = io.popen(cmd)
  assert(handle, 'cannot execute command "' .. cmd .. '"')

  local output = handle:read('*a')
  handle:close()

  return output
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
local function out_lines_to_files(lines)
  local files = {}
  for _, line in pairs(lines) do
    local line_files = line_to_files(line)
    for _, file in pairs(line_files) do
      table.insert(files, file)
    end
  end
  return files
end

---@return File[]
function parser.retrieve_files()
  local git_status = execute_cmd('git status -s')
  local lines = split(git_status, '\n')
  return out_lines_to_files(lines)
end

return parser
