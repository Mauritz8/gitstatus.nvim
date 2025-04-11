local parse = require('gitstatus.parse')
local git = require('gitstatus.git')
local out_formatter = require('gitstatus.out_formatter')
local window = require('gitstatus.window')

local M = {}

---@type Line[]
local buf_lines = {}

-- TODO: recalculate window size and position on buffer refresh
---@param buf integer
---@param namespace integer
---@return string?
local function refresh_buffer(buf, namespace)
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
    vim.api.nvim_win_set_cursor(0, {1, 0})
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
  refresh_buffer(buf, namespace)
end

---@param buf integer
---@param namespace integer
local function stage_all(buf, namespace)
  git.stage_all()
  refresh_buffer(buf, namespace)
end

function M.open_status_win()
  local buf = vim.api.nvim_create_buf(false, true)
  local namespace = vim.api.nvim_create_namespace("")
  vim.api.nvim_set_hl(namespace, "staged", { fg = "#26A641" })
  vim.api.nvim_set_hl(namespace, "not_staged", { fg = "#D73A49" })
  vim.api.nvim_set_hl_ns(namespace)

  local err = refresh_buffer(buf, namespace)
  if err ~= nil then
    vim.print(err)
    return
  end

  local parent_win_width = vim.api.nvim_win_get_width(0)
  local parent_win_height = vim.api.nvim_win_get_height(0)
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
end

return M
