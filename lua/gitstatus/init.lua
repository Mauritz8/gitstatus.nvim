local File = require('gitstatus.file')
local Line = require('gitstatus.line')
local StringUtils = require('gitstatus.string_utils')
local Window = require('gitstatus.window')
local git = require('gitstatus.git')
local out_formatter = require('gitstatus.out_formatter')
local parse = require('gitstatus.parse')

local M = {}

---@type Line[]
local buf_lines = {}

---@type integer?
local window = nil

---@type integer?
local help_window = nil

local WINDOW_WIDTH = 80

local function toggle_help_window()
  if help_window ~= nil then
    vim.api.nvim_win_close(help_window, false)
    help_window = nil
    return
  end

  local lines = out_formatter.make_help_window_msg()
  local lines_strings = Line.get_lines_strings(lines)
  local buf = vim.api.nvim_create_buf(false, true)
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

  local pos = vim.api.nvim_win_get_position(0)
  local row, col = unpack(pos)
  help_window = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = WINDOW_WIDTH,
    height = #lines_strings,
    row = row + vim.api.nvim_win_get_height(0) + 1,
    col = col,
    zindex = 100,
    style = 'minimal',
    border = { '╔', '═', '╗', '║', '╝', '═', '╚', '║' },
  })
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
    vim.notify(err, vim.log.levels.ERROR)
    vim.cmd.quit()
    return
  end
  local paths = parse.git_status(status_out)
  local files = File.paths_to_files(paths)

  local branch_out, err2 = git.branch()
  if err2 ~= nil then
    vim.notify(err2, vim.log.levels.ERROR)
    vim.cmd.quit()
    return
  end
  local branch, err3 = parse.git_branch(branch_out)
  if err3 ~= nil then
    vim.notify(err3, vim.log.levels.ERROR)
    vim.cmd.quit()
    return
  end

  buf_lines = out_formatter.format_out_lines(branch, files)
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  local lines_strings = Line.get_lines_strings(buf_lines)
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

  local width = WINDOW_WIDTH
  local optimal_height = Window.height(lines_strings, parent_win_height)
  local max_height = 15
  local height = optimal_height > max_height and max_height or optimal_height
  assert(window ~= nil)
  vim.api.nvim_win_set_config(window, {
    relative = 'editor',
    width = width,
    height = height,
    row = Window.row(parent_win_height, height),
    col = Window.column(parent_win_width, width),
  })
  vim.api.nvim_win_set_cursor(window, { get_new_cursor_row(cursor_file), col })

  if help_window ~= nil then
    vim.api.nvim_win_close(help_window, false)
    help_window = nil
    toggle_help_window()
  end
end

---@param file File
---@return fun(file: string, cwd: string): string?
local function get_toggle_stage_file_func(file)
  if file.state == File.STATE.staged then
    return file.type == File.EDIT_TYPE.added and git.unstage_added_file
      or git.unstage_modified_file
  else
    return git.stage_file
  end
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
  if line.file == nil then
    vim.notify(
      'Unable to stage/unstage file: invalid line',
      vim.log.levels.WARN
    )
    return
  end

  local git_repo_root_dir, err = git.repo_root_dir()
  if err ~= nil then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local toggle_stage_file_func = get_toggle_stage_file_func(line.file)
  err = toggle_stage_file_func(line.file.path, git_repo_root_dir)
  if err ~= nil then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  if line.file.orig_path ~= nil then
    err = toggle_stage_file_func(line.file.orig_path, git_repo_root_dir)
    if err ~= nil then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
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
    vim.notify('Unable to open file: invalid line', vim.log.levels.WARN)
    return
  end

  vim.cmd.quit()
  local open_file_cmd = vim.fn.bufexists(line.file.path) == 1 and 'buffer'
    or 'e'
  vim.api.nvim_cmd({ cmd = open_file_cmd, args = { line.file.path } }, {})
end

---@param status_win_buf integer
---@param status_win_namespace integer
---@param parent_win_width number
---@param parent_win_height number
local function open_commit_prompt(
  status_win_buf,
  status_win_namespace,
  parent_win_width,
  parent_win_height
)
  if Line.staged_files(buf_lines) == 0 then
    vim.notify('Unable to commit: no staged files', vim.log.levels.WARN)
    return
  end

  if Line.unmerged_files(buf_lines) > 0 then
    vim.notify(
      'Committing is not possible because you have unmerged files.',
      vim.log.levels.WARN
    )
    return
  end

  local git_repo_root_dir, err = git.repo_root_dir()
  if err ~= nil then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(buf, git_repo_root_dir .. '/.git/COMMIT_EDITMSG')
  vim.api.nvim_buf_call(buf, vim.cmd.edit)
  local help_msg = out_formatter.make_commit_init_msg()
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, help_msg)

  local height = 7
  local pos = vim.api.nvim_win_get_position(0)
  local row, col = unpack(pos)
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = WINDOW_WIDTH,
    height = height,
    row = row - height - 2,
    col = col,
    title = 'Git commit',
    border = { '╔', '═', '╗', '║', '╝', '═', '╚', '║' },
  })
  vim.cmd('silent write')
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  vim.api.nvim_create_autocmd({ 'QuitPre' }, {
    buffer = buf,
    callback = function(ev)
      local commit_msg_file = vim.api.nvim_buf_get_name(ev.buf)

      local msg = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, true)
      local is_not_comment = function(str)
        return not StringUtils.str_starts_with(str, '#')
      end
      local msg_without_comments = StringUtils.filter(msg, is_not_comment)
      vim.api.nvim_buf_set_lines(ev.buf, 0, -1, true, msg_without_comments)
      vim.cmd('silent write')

      local _, err2 = git.commit(commit_msg_file)

      -- redraw before sending notification to avoid annoying prompt
      vim.cmd('redraw')

      if err2 ~= nil then
        vim.notify(
          StringUtils.strip_trailing_newline(err2),
          vim.log.levels.WARN
        )
      else
        vim.notify('Commit successful!', vim.log.levels.INFO)
      end

      vim.api.nvim_buf_delete(ev.buf, { force = true })

      refresh_buffer(
        status_win_buf,
        status_win_namespace,
        nil,
        parent_win_width,
        parent_win_height
      )
    end,
  })
end

---@param buf integer
---@param namespace integer
---@param parent_win_width integer
---@param parent_win_height integer
local function register_keybindings(
  buf,
  namespace,
  parent_win_width,
  parent_win_height
)
  vim.keymap.set('n', 'q', function()
    vim.cmd.quit()
  end, {
    buffer = buf,
    desc = 'Quit',
  })
  vim.keymap.set('n', 's', function()
    toggle_stage_file(buf, namespace, parent_win_width, parent_win_height)
  end, {
    buffer = buf,
    desc = 'Stage/unstage file',
  })
  vim.keymap.set('n', 'a', function()
    git.stage_all()
    refresh_buffer(buf, namespace, nil, parent_win_width, parent_win_height)
  end, {
    buffer = buf,
    desc = 'Stage all changes',
  })
  vim.keymap.set('n', 'j', go_next_file, {
    buffer = buf,
    desc = 'Go to next file',
  })
  vim.keymap.set('n', 'k', go_prev_file, {
    buffer = buf,
    desc = 'Go to previous file',
  })
  vim.keymap.set('n', 'o', open_file, {
    buffer = buf,
    desc = 'Open file',
  })
  vim.keymap.set('n', 'c', function()
    open_commit_prompt(buf, namespace, parent_win_width, parent_win_height)
  end, {
    buffer = buf,
    desc = 'Open commit prompt',
  })
  vim.keymap.set('n', '?', toggle_help_window, {
    buffer = buf,
    desc = 'Toggle help window',
  })
end

function M.open_status_win()
  local nvim_notify_exists, nvim_notify = pcall(require, 'notify')
  if nvim_notify_exists then
    vim.notify = nvim_notify
  end

  if window ~= nil then
    vim.api.nvim_set_current_win(window)
    return
  end

  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(buf, 'gitstatus.nvim')
  local namespace = vim.api.nvim_create_namespace('')
  local parent_win_width = vim.api.nvim_win_get_width(0)
  local parent_win_height = vim.api.nvim_win_get_height(0)

  register_keybindings(buf, namespace, parent_win_width, parent_win_height)

  vim.api.nvim_create_autocmd({ 'QuitPre' }, {
    buffer = buf,
    once = true,
    callback = function()
      vim.api.nvim_buf_delete(buf, {})
      window = nil
      if help_window ~= nil then
        vim.api.nvim_win_close(help_window, false)
        help_window = nil
      end
    end,
  })

  local default_width = 40
  local default_height = 10
  window = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = default_width,
    height = default_height,
    row = Window.row(parent_win_height, default_height),
    col = Window.column(parent_win_width, default_width),
    title = 'Git status',
    border = { '╔', '═', '╗', '║', '╝', '═', '╚', '║' },
  })
  vim.api.nvim_win_set_hl_ns(window, namespace)
  refresh_buffer(buf, namespace, nil, parent_win_width, parent_win_height)
end

return M
