local M = {}

---@class StatusWin
---@field win string
---@field buf string
---@field prev_win string
---@field files File[]
StatusWin = {}

---@enum FILE_STATE
FILE_STATE = {
  modified = 0,
  staged = 1,
  new = 2
}

---@class File
---@field name string
---@field state FILE_STATE
File = {}


---@type StatusWin?
State = nil

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

---@param lines string[]
---@return File[]
local function out_lines_to_files(lines)
  local files = {}
  for _, line in pairs(lines) do
    local state_str = line:sub(1, 2)
    local is_valid_state = state_str == 'M ' or state_str == ' M'
        or state_str == '??'
    assert(is_valid_state, 'git file has invalid state')

    local state = state_str == 'M ' and FILE_STATE.staged
        or state_str == ' M' and FILE_STATE.modified
        or FILE_STATE.new
    local file = {
      name = line:sub(4),
      state = state
    }
    table.insert(files, file)
  end
  return files
end

---@return File[]
local function retrive_files()
  local git_status = execute_cmd('git status -s')
  local lines = split(git_status, '\n')
  return out_lines_to_files(lines)
end

---@param file_state FILE_STATE
---@return string
local function prefix(file_state)
  return file_state == FILE_STATE.staged and 'S '
      or file_state == FILE_STATE.modified and 'M '
      or '??'
end

---@param file_state FILE_STATE
---@return string
local function highlight_group(file_state)
  return file_state == FILE_STATE.staged and 'Added'
      or file_state == FILE_STATE.modified and 'Removed'
      or 'Removed'
end

local function open_status_win(files)
  local buf = vim.api.nvim_create_buf(false, true)
  for i, file in pairs(files) do
    local line_nr = i - 1
    local line = prefix(file.state) .. ' ' .. file.name
    local hl_group = highlight_group(file.state)
    vim.api.nvim_buf_set_lines(buf, line_nr, line_nr, true, {line})
    vim.api.nvim_buf_add_highlight(buf, -1, hl_group, line_nr, 0, 2)
  end

  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>',
      '<CMD>lua require("gitstatus").open_file_current_line()<CR>', {})

  local win = vim.api.nvim_open_win(buf, true, {
    split = 'left',
    width = 50,
  })
  return win, buf
end

function M.toggle_status_win()
  local current_win = vim.api.nvim_get_current_win()
  if State == nil or not vim.api.nvim_win_is_valid(State.win) then
    local files = retrive_files()
    local win, buf = open_status_win(files)
    State = { win = win, buf = buf, prev_win = current_win, files = files }
  else
    vim.api.nvim_set_current_win(State.win)
  end
end

function M.open_file_current_line()
  if State == nil or not vim.api.nvim_win_is_valid(State.win) then
    return
  end

  local pos = vim.api.nvim_win_get_cursor(State.win)
  local row = pos[1]
  local file = State.files[row]
  vim.api.nvim_set_current_win(State.prev_win)
  vim.cmd('e ' .. file.name)
end

return M
