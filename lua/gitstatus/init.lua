local parse = require('gitstatus.parse')
local git = require('gitstatus.git')
local out_formatter = require('gitstatus.out_formatter')
local window = require('gitstatus.window')
local Line = require('gitstatus.line')

local M = {}

---@type Line[]
local buf_lines = {}

local parent_win_width = vim.api.nvim_win_get_width(0)
local parent_win_height = vim.api.nvim_win_get_height(0)

---@return integer
local function default_cursor_row()
  local first_file_index = Line.next_file_index(buf_lines, 0)
  if first_file_index == nil then
    return 0
  end
  return first_file_index
end

---@param cursor_file File?
---@return integer
local function get_new_cursor_row(cursor_file)
  local default = default_cursor_row()
  if cursor_file == nil then
    return default
  end

  local cursor_file_index = Line.line_index_of_file(buf_lines, cursor_file)
  if cursor_file_index == nil then
    return default
  end
  return cursor_file_index
end

-- TODO: recalculate window size and position on buffer refresh
---@param buf integer
---@param namespace integer
---@param cursor_file File?
---@return string?
local function refresh_buffer(buf, namespace, cursor_file)
  local col = vim.api.nvim_win_get_cursor(0)[2]
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})

  local status_out, err = git.status()
  if err ~= nil then
    return err
  end
  local files = parse.git_status(status_out)

  local branch_out, err2 = git.branch()
  if err2 ~= nil then
    return err2
  end
  local branch = parse.git_branch(branch_out)
  if branch == nil then
    return "Unable to find current branch"
  end
  buf_lines = out_formatter.format_out_lines(branch, files)
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

  if vim.api.nvim_win_get_buf(0) == buf then
    local numberwidth = vim.api.nvim_get_option_value('numberwidth', {})
    local width = window.width(buf_lines, numberwidth, parent_win_width)
    local height = window.height(buf_lines, parent_win_height)
    vim.api.nvim_win_set_config(0, {
      relative = 'editor',
      width = width,
      height = height,
      row = window.row(parent_win_height, height),
      col = window.column(parent_win_width, width),
    })

    -- in order to essentially refresh the buffer
    -- without it the buffer shows a blank line at the bottom sometimes
    -- which is only fixed by moving the cursor up one row
    vim.api.nvim_win_set_cursor(0, {1, 0})

    vim.api.nvim_win_set_cursor(0, {get_new_cursor_row(cursor_file), col})
  end
end

---@param buf integer
---@param namespace integer
local function toggle_stage_file(buf, namespace)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = buf_lines[row]
  if line.file == nil then
    vim.print("Unable to stage file: invalid line")
    return
  end
  if line.file.state == FILE_STATE.staged then
    local err = git.unstage_file(line.file.name)
    if err ~= nil then
      vim.print(err)
      return
    end
  else
    local err = git.stage_file(line.file.name)
    if err ~= nil then
      vim.print(err)
      return
    end
  end

  local cursor_file_index = Line.next_file_index(buf_lines, row)
  if cursor_file_index == nil then
    cursor_file_index = Line.prev_file_index(buf_lines, row)
  end
  local cursor_file = nil
  if cursor_file_index ~= nil then
    cursor_file = buf_lines[cursor_file_index].file
  end
  refresh_buffer(buf, namespace, cursor_file)
end

---@param buf integer
---@param namespace integer
local function stage_all(buf, namespace)
  git.stage_all()
  refresh_buffer(buf, namespace, nil)
end

local function go_next_file()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]

  local new_row = Line.next_file_index(buf_lines, row)
  if new_row == nil then
    if row < #buf_lines then
      new_row = row + 1
    else
      new_row = row
    end
  end
  vim.api.nvim_win_set_cursor(0, {new_row, col})
end

local function go_prev_file()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]

  local new_row = Line.prev_file_index(buf_lines, row)
  if new_row == nil then
    if row > 1 then
      new_row = row - 1
    else
      new_row = row
    end
  end
  vim.api.nvim_win_set_cursor(0, {new_row, col})
end

function M.open_status_win()
  local buf = vim.api.nvim_create_buf(false, true)
  local namespace = vim.api.nvim_create_namespace("")
  vim.api.nvim_set_hl(namespace, "staged", { fg = "#26A641" })
  vim.api.nvim_set_hl(namespace, "not_staged", { fg = "#D73A49" })
  vim.api.nvim_set_hl_ns(namespace)

  local err = refresh_buffer(buf, namespace, nil)
  if err ~= nil then
    vim.print(err)
    return
  end

  parent_win_width = vim.api.nvim_win_get_width(0)
  parent_win_height = vim.api.nvim_win_get_height(0)
  local numberwidth = vim.api.nvim_get_option_value('numberwidth', {})
  local width = window.width(buf_lines, numberwidth, parent_win_width)
  local height = window.height(buf_lines, parent_win_height)
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = window.row(parent_win_height, height),
    col = window.column(parent_win_width, width),
  })
  go_next_file()

  vim.keymap.set('n', 'q', '<CMD>q<CR>', {
    buffer = true,
    desc = "Quit",
  })

  vim.keymap.set('n', 's', function () toggle_stage_file(buf, namespace) end, {
    buffer = true,
    desc = "Stage/unstage file",
  })

  vim.keymap.set('n', 'a', function () stage_all(buf, namespace) end, {
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
end

return M
