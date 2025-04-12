local parse = require('gitstatus.parse')
local git = require('gitstatus.git')
local out_formatter = require('gitstatus.out_formatter')
local Window = require('gitstatus.window')
local Line = require('gitstatus.line')

local M = {}

---@type Line[]
local buf_lines = {}

---@type integer?
local window = nil

local parent_win_width = vim.api.nvim_win_get_width(0)
local parent_win_height = vim.api.nvim_win_get_height(0)

---@param msg string
local function err_msg(msg)
  vim.api.nvim_echo({ { msg, "ErrorMsg" } }, false, {})
end

---@param msg string
local function warn_msg(msg)
  vim.api.nvim_echo({ { msg, "WarningMsg" } }, false, {})
end

---@param cursor_file File?
---@return integer
local function get_new_cursor_row(cursor_file)
  local default = Line.next_file_index(buf_lines, 0) or 1
  if cursor_file == nil then
    return default
  end
  return Line.line_index_of_file(buf_lines, cursor_file) or default
end

---@param buf integer
---@param namespace integer
---@param cursor_file File?
local function refresh_buffer(buf, namespace, cursor_file)
  local col = vim.api.nvim_win_get_cursor(0)[2]

  local status_out, err = git.status()
  if err ~= nil then
    err_msg(err)
    return
  end
  local files = parse.git_status(status_out)

  local branch_out, err2 = git.branch()
  if err2 ~= nil then
    err_msg(err2)
    return
  end
  local branch = parse.git_branch(branch_out)
  if branch == nil then
    err_msg("Unable to find current branch")
    return
  end

  buf_lines = out_formatter.format_out_lines(branch, files)
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
  for i, line in ipairs(buf_lines) do
    local line_nr = i - 1
    vim.api.nvim_buf_set_lines(buf, line_nr, line_nr, true, {line.str})
    vim.api.nvim_buf_set_extmark(buf, namespace, line_nr, 0, {
      end_col = line.str:len(),
      hl_group = line.highlight_group,
    })
  end
  vim.api.nvim_buf_set_lines(buf, -2, -1, true, {})
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  local numberwidth = vim.api.nvim_get_option_value('numberwidth', {})
  local width = Window.width(buf_lines, numberwidth, parent_win_width)
  local height = Window.height(buf_lines, parent_win_height)
  vim.api.nvim_win_set_config(0, {
    relative = 'editor',
    width = width,
    height = height,
    row = Window.row(parent_win_height, height),
    col = Window.column(parent_win_width, width),
  })

  -- in order to essentially refresh the buffer
  -- without it the buffer shows a blank line at the bottom sometimes
  -- which is only fixed by moving the cursor up one row
  vim.api.nvim_win_set_cursor(0, {1, 0})

  vim.api.nvim_win_set_cursor(0, {get_new_cursor_row(cursor_file), col})
end

local function quit()
  vim.api.nvim_win_close(0, false)
  window = nil
end

---@param line Line
---@return boolean # success
local function toggle_stage_line(line)
  if line.file == nil then
    warn_msg("Unable to stage/unstage file: invalid line")
    return false
  end

  if line.file.state ~= FILE_STATE.staged then
    local err = git.stage_file(line.file.name)
    if err ~= nil then
      err_msg(err)
      return false
    end
    return true
  end

  if line.file.type == FILE_EDIT_TYPE.renamed then
    local old_name, new_name, err = parse.git_renamed_file(line.file.name)
    if err ~= nil then
      err_msg('Unable to unstage file: ' .. err)
      return false
    end
    err = git.unstage_file(old_name)
    if err ~= nil then
      err_msg(err)
      return false
    end
    err = git.unstage_file(new_name)
    if err ~= nil then
      err_msg(err)
      return false
    end
    return true
  end

  local err = git.unstage_file(line.file.name)
  if err ~= nil then
    err_msg(err)
    return false
  end
  return true
end

local function go_next_file()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]

  local new_row = Line.next_file_index(buf_lines, row)
      or row < #buf_lines and row + 1
      or row
  vim.api.nvim_win_set_cursor(0, {new_row, col})
end

local function go_prev_file()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]

  local new_row = Line.prev_file_index(buf_lines, row)
      or row > 1 and row - 1
      or row
  vim.api.nvim_win_set_cursor(0, {new_row, col})
end

local function open_file()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = buf_lines[row]
  if line.file == nil then
    warn_msg("Unable to open file: invalid line")
    return
  end

  local name = line.file.name
  if line.file.type == FILE_EDIT_TYPE.renamed then
    local _, new_name, err = parse.git_renamed_file(line.file.name)
    if err ~= nil then
      err_msg('Unable to open file: ' .. err)
      return
    end
    name = new_name
  end

  quit()
  vim.cmd('e ' .. name)
end

function M.open_status_win()
  if window ~= nil then
    vim.api.nvim_set_current_win(window)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local default_width = 1
  local default_height = 1
  window = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = default_width,
    height = default_height,
    row = Window.row(parent_win_height, default_height),
    col = Window.column(parent_win_width, default_width),
  })
  local namespace = vim.api.nvim_create_namespace("")
  vim.api.nvim_set_hl(namespace, "staged", { fg = "#26A641" })
  vim.api.nvim_set_hl(namespace, "not_staged", { fg = "#D73A49" })
  vim.api.nvim_win_set_hl_ns(window, namespace)

  refresh_buffer(buf, namespace, nil)

  vim.keymap.set('n', 'q', quit, {
    buffer = true,
    desc = "Quit",
  })

  local function toggle_stage_file()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = buf_lines[row]
    local success = toggle_stage_line(line)
    if not success then return end

    local cursor_file_index = Line.next_file_index(buf_lines, row)
        or Line.prev_file_index(buf_lines, row)
    local cursor_file =
        cursor_file_index ~= nil and buf_lines[cursor_file_index].file
        or nil
    refresh_buffer(buf, namespace, cursor_file)
  end
  vim.keymap.set('n', 's', toggle_stage_file, {
    buffer = true,
    desc = "Stage/unstage file",
  })

  local function stage_all()
    git.stage_all()
    refresh_buffer(buf, namespace, nil)
  end
  vim.keymap.set('n', 'a', stage_all, {
    buffer = true,
    desc = "Stage all changes",
  })
  vim.keymap.set('n', 'j', go_next_file, {
    buffer = true,
    desc = "Go to next file",
  })
  vim.keymap.set('n', 'k', go_prev_file, {
    buffer = true,
    desc = "Go to previous file",
  })
  vim.keymap.set('n', '<CR>', open_file, {
    buffer = true,
    desc = "Open file",
  })
end

return M
