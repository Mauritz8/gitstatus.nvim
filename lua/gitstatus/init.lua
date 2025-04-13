local Line = require('gitstatus.line')
local Window = require('gitstatus.window')
local file = require('gitstatus.file')
local git = require('gitstatus.git')
local out_formatter = require('gitstatus.out_formatter')
local parse = require('gitstatus.parse')

local M = {}

---@type Line[]
local buf_lines = {}

---@type integer?
local window = nil

---@param msg string
local function echo_msg(msg)
  vim.api.nvim_echo({ { msg } }, false, {})
end

---@param msg string
local function err_msg(msg)
  vim.api.nvim_echo({ { msg, 'ErrorMsg' } }, false, {})
end

---@param msg string
local function warn_msg(msg)
  vim.api.nvim_echo({ { msg, 'WarningMsg' } }, false, {})
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

---@param lines Line[]
---@return string[]
local function get_lines_strings(lines)
  local strings = {}
  for _, line in ipairs(lines) do
    local str = ''
    for _, part in ipairs(line.parts) do
      str = str .. part.str
    end
    table.insert(strings, str)
  end
  return strings
end

---@param buf integer
---@param namespace integer
---@param cursor_file File?
---@param parent_win_width number
---@param parent_win_height number
local function refresh_buffer(
  buf,
  namespace,
  cursor_file,
  parent_win_width,
  parent_win_height
)
  local col = vim.api.nvim_win_get_cursor(0)[2]

  local status_out, err = git.status()
  if err ~= nil then
    err_msg(err)
    vim.cmd('q')
    return
  end
  local files = parse.git_status(status_out)

  local branch_out, err2 = git.branch()
  if err2 ~= nil then
    err_msg(err2)
    vim.cmd('q')
    return
  end
  local branch = parse.git_branch(branch_out)
  if branch == nil then
    err_msg('Unable to find current branch')
    vim.cmd('q')
    return
  end

  buf_lines = out_formatter.format_out_lines(branch, files)
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  local lines_strings = get_lines_strings(buf_lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines_strings)
  for i, line in ipairs(buf_lines) do
    local pos = 0
    for _, part in ipairs(line.parts) do
      vim.api.nvim_buf_set_extmark(buf, namespace, i - 1, pos, {
        end_col = pos + part.str:len(),
        hl_group = part.hl_group,
      })
      pos = pos + part.str:len()
    end
  end
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  local numberwidth = vim.api.nvim_get_option_value('numberwidth', {})
  local width = Window.width(lines_strings, numberwidth, parent_win_width)
  local height = Window.height(lines_strings, parent_win_height)
  vim.api.nvim_win_set_config(0, {
    relative = 'editor',
    width = width,
    height = height,
    row = Window.row(parent_win_height, height),
    col = Window.column(parent_win_width, width),
  })
  vim.api.nvim_win_set_cursor(0, { get_new_cursor_row(cursor_file), col })
end

-- TODO: refactor this function
---@param line Line
---@return boolean # success
local function toggle_stage_line(line)
  if line.file == nil then
    warn_msg('Unable to stage/unstage file: invalid line')
    return false
  end

  if line.file.state ~= file.FILE_STATE.staged then
    local err = git.stage_file(line.file.name)
    if err ~= nil then
      err_msg(err)
      return false
    end
    return true
  end

  if line.file.type == file.FILE_EDIT_TYPE.renamed then
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

---@param buf integer
---@param namespace integer
---@param parent_win_width number
---@param parent_win_height number
local function toggle_stage_file(
  buf,
  namespace,
  parent_win_width,
  parent_win_height
)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = buf_lines[row]
  local success = toggle_stage_line(line)
  if not success then
    return
  end

  local cursor_file_index = Line.next_file_index(buf_lines, row)
    or Line.prev_file_index(buf_lines, row)
  local cursor_file = cursor_file_index ~= nil
      and buf_lines[cursor_file_index].file
    or nil
  refresh_buffer(
    buf,
    namespace,
    cursor_file,
    parent_win_width,
    parent_win_height
  )
end

local function go_next_file()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]

  local motion_count = vim.api.nvim_get_vvar('count')
  local new_row = motion_count > 0 and row + motion_count
    or Line.next_file_index(buf_lines, row)
    or row < #buf_lines and row + 1
    or row
  vim.api.nvim_win_set_cursor(0, { new_row, col })
end

local function go_prev_file()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]

  local motion_count = vim.api.nvim_get_vvar('count')
  local new_row = motion_count > 0 and row - motion_count
    or Line.prev_file_index(buf_lines, row)
    or row > 1 and row - 1
    or row
  vim.api.nvim_win_set_cursor(0, { new_row, col })
end

local function open_file()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = buf_lines[row]
  if line.file == nil then
    warn_msg('Unable to open file: invalid line')
    return
  end

  local name = line.file.name
  if line.file.type == file.FILE_EDIT_TYPE.renamed then
    local _, new_name, err = parse.git_renamed_file(line.file.name)
    if err ~= nil then
      err_msg('Unable to open file: ' .. err)
      return
    end
    name = new_name
  end

  vim.cmd('q')
  vim.cmd('e ' .. name)
end

---@param lines string[]
---@return string[]
local function filter_out_lines_with_comment(lines)
  local new_lines = {}
  for _, line in ipairs(lines) do
    if line:sub(1, 1) ~= '#' then
      table.insert(new_lines, line)
    end
  end
  return new_lines
end

local function open_commit_prompt()
  if Line.staged_files(buf_lines) == 0 then
    warn_msg('Unable to commit: no staged files')
    return
  end

  vim.cmd('q')
  local git_commit_file = '.git/COMMIT_EDITMSG'
  vim.cmd('new ' .. git_commit_file)

  local help_lines = {
    '',
    '# Please enter the commit message for your changes. Lines starting',
    "# with '#' will be ignored, and an empty message aborts the commit.",
  }
  vim.api.nvim_buf_set_lines(0, 0, -1, true, help_lines)

  vim.api.nvim_create_autocmd({ 'QuitPre' }, {
    pattern = { git_commit_file },
    once = true,
    callback = function(ev)
      local file_saved = not vim.opt.modified:get()
      if not file_saved then
        vim.api.nvim_buf_delete(ev.buf, { force = true })
        echo_msg('Aborting commit: commit message not saved')
        return
      end
      local lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, true)
      local msg = filter_out_lines_with_comment(lines)
      local success_message, err = git.commit(msg)
      if err ~= nil then
        err_msg(err)
      else
        echo_msg('Commit successful!')
        echo_msg(success_message)
      end
    end,
  })
end

---@param parent_win_width number
---@param parent_win_height number
local function open_help_window(parent_win_width, parent_win_height)
  local lines = {
    {
      parts = {
        {
          str = 's',
          hl_group = 'Label',
        },
        {
          str = ' - ',
          hl_group = '',
        },
        {
          str = 'Stage/unstage the file on the current line',
          hl_group = 'Function',
        },
      },
      file = nil,
    },
    {
      parts = {
        {
          str = 'a',
          hl_group = 'Label',
        },
        {
          str = ' - ',
          hl_group = '',
        },
        {
          str = 'Stage all changes',
          hl_group = 'Function',
        },
      },
      file = nil,
    },
    {
      parts = {
        {
          str = 'c',
          hl_group = 'Label',
        },
        {
          str = ' - ',
          hl_group = '',
        },
        {
          str = 'Open commit prompt',
          hl_group = 'Function',
        },
      },
      file = nil,
    },
    {
      parts = {
        {
          str = '<CR> (Enter)',
          hl_group = 'Label',
        },
        {
          str = ' - ',
          hl_group = '',
        },
        {
          str = 'Open file on the current line',
          hl_group = 'Function',
        },
      },
      file = nil,
    },
    {
      parts = {
        {
          str = 'q',
          hl_group = 'Label',
        },
        {
          str = ' - ',
          hl_group = '',
        },
        {
          str = 'Close window',
          hl_group = 'Function',
        },
      },
      file = nil,
    },
  }
  local lines_strings = get_lines_strings(lines)
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines_strings)
  local namespace = vim.api.nvim_create_namespace('')
  for i, line in ipairs(lines) do
    local pos = 0
    for _, part in ipairs(line.parts) do
      vim.api.nvim_buf_set_extmark(buf, namespace, i - 1, pos, {
        end_col = pos + part.str:len(),
        hl_group = part.hl_group,
      })
      pos = pos + part.str:len()
    end
  end

  local numberwidth = vim.api.nvim_get_option_value('numberwidth', {})
  local width = Window.width(lines_strings, numberwidth, parent_win_width)
  local height = Window.height(lines_strings, parent_win_height)
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = Window.row(parent_win_height, height),
    col = Window.column(parent_win_width, width),
    title = 'Keymappings',
    border = { '╔', '═', '╗', '║', '╝', '═', '╚', '║' },
  })

  vim.keymap.set('n', 'q', function()
    vim.cmd('q')
  end, {
    buffer = true,
    desc = 'Quit',
  })
end

function M.open_status_win()
  if window ~= nil then
    vim.api.nvim_set_current_win(window)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_create_autocmd({ 'QuitPre' }, {
    buffer = buf,
    once = true,
    callback = function()
      window = nil
    end,
  })

  local default_width = 40
  local default_height = 10
  local parent_win_width = vim.api.nvim_win_get_width(0)
  local parent_win_height = vim.api.nvim_win_get_height(0)
  window = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = default_width,
    height = default_height,
    row = Window.row(parent_win_height, default_height),
    col = Window.column(parent_win_width, default_width),
    title = 'Git status',
    border = { '╔', '═', '╗', '║', '╝', '═', '╚', '║' },
  })
  local namespace = vim.api.nvim_create_namespace('')
  vim.api.nvim_set_hl(namespace, 'staged', { fg = '#26A641' })
  vim.api.nvim_set_hl(namespace, 'not_staged', { fg = '#D73A49' })
  vim.api.nvim_win_set_hl_ns(window, namespace)

  refresh_buffer(buf, namespace, nil, parent_win_width, parent_win_height)

  vim.keymap.set('n', 'q', function()
    vim.cmd('q')
  end, {
    buffer = true,
    desc = 'Quit',
  })
  vim.keymap.set('n', 's', function()
    toggle_stage_file(buf, namespace, parent_win_width, parent_win_height)
  end, {
    buffer = true,
    desc = 'Stage/unstage file',
  })
  vim.keymap.set('n', 'a', function()
    git.stage_all()
    refresh_buffer(buf, namespace, nil, parent_win_width, parent_win_height)
  end, {
    buffer = true,
    desc = 'Stage all changes',
  })
  vim.keymap.set('n', 'j', go_next_file, {
    buffer = true,
    desc = 'Go to next file',
  })
  vim.keymap.set('n', 'k', go_prev_file, {
    buffer = true,
    desc = 'Go to previous file',
  })
  vim.keymap.set('n', '<CR>', open_file, {
    buffer = true,
    desc = 'Open file',
  })
  vim.keymap.set('n', 'c', open_commit_prompt, {
    buffer = true,
    desc = 'Open commit prompt',
  })
  vim.keymap.set('n', '?', function()
    open_help_window(parent_win_width, parent_win_height)
  end, {
    buffer = true,
    desc = 'Open help window',
  })
end

return M
