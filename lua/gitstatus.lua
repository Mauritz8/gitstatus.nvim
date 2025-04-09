local M = {}

---@enum FILE_STATE
local FILE_STATE = {
  staged = 0,
  not_staged = 1,
  untracked = 2
}

---@enum FILE_EDIT_TYPE
local FILE_EDIT_TYPE = {
  modified = 0,
  new = 1,
  deleted = 2,
  renamed = 3,
  none = 4,
}

---@class File
---@field name string
---@field state FILE_STATE
---@field type FILE_EDIT_TYPE
local File = {}


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
local function retrieve_files()
  local git_status = execute_cmd('git status -s')
  local lines = split(git_status, '\n')
  return out_lines_to_files(lines)
end

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
local function highlight_group(file_state)
  return file_state == FILE_STATE.staged and 'Added' or 'Removed'
end

---@param buf integer
---@param i integer
---@param file File
local function set_line(buf, i, file)
  local line_nr = i - 1
  local line = prefix(file.type) .. file.name
  vim.api.nvim_buf_set_lines(buf, line_nr, line_nr, true, {line})

  local ns_id = vim.api.nvim_create_namespace("")
  local hl_group = highlight_group(file.state)
  vim.api.nvim_buf_set_extmark(buf, ns_id, line_nr, 0, {
    end_col = string.len(line),
    hl_group = hl_group,
  })
end

function M.open_status_win()
  local buf = vim.api.nvim_create_buf(false, true)

  local files = retrieve_files()
  if #files == 0 then
    local content = "nothing to commit, working tree clean"
    vim.api.nvim_buf_set_lines(buf, 0, 0, true, {content})
  else
    for i, file in pairs(files) do
      set_line(buf, i, file)
    end
  end


  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<CMD>:q<CR>', {})

  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = 10,
    col = 60,
    width = 65,
    height = 15,
  })
end

return M
