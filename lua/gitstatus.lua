local parser = require("parser")
local git = require("git_actions")

local M = {}

---@class Line
---@field str string
---@field highlight_group string
---@field file File?
Line = {}

---@type Line[]
local buf_lines = {}

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
local function get_highlight_group(file_state)
  return file_state == FILE_STATE.staged and 'staged' or 'not_staged'
end

---@param files File[]
---@return File[], File[], File[]
local function split_files_by_state(files)
  local staged = {}
  local not_staged = {}
  local untracked  = {}
  for _, file in ipairs(files) do
    if file.state == FILE_STATE.staged then
      table.insert(staged, file)
    elseif file.state == FILE_STATE.not_staged then
      table.insert(not_staged, file)
    elseif file.state == FILE_STATE.untracked then
      table.insert(untracked, file)
    end
  end
  return staged, not_staged, untracked
end

---@param files File[]
---@return Line[]
local function get_lines(files)
  local lines = {}

  local branch, err = parser.branch()
  if err ~= nil then
    vim.print(err)
  else
    table.insert(lines, {
      str = "Branch: " .. branch,
      highlight_group = nil,
      file = nil,
    })
  end

  if #files == 0 then
    if #lines > 0 then
      table.insert(lines, { str = "", highlight_group = nil, file = nil, })
    end
    table.insert(lines, {
      str = "nothing to commit, working tree clean",
      highlight_group = nil,
      file = nil,
    })
    return lines
  end

  local staged, not_staged, untracked = split_files_by_state(files)
  local file_table = { staged, not_staged, untracked }
  local name = function(i)
    return i == 1 and "Staged:" or i == 2 and "Not staged:" or "Untracked:"
  end
  for i, files_of_type in ipairs(file_table) do
    if #files_of_type > 0 then
      if #lines > 0 then
        table.insert(lines, { str = "", highlight_group = nil, file = nil, })
      end
      table.insert(lines, { str = name(i); highlight_group = nil, file = nil, })
    end
    for _, file in ipairs(files_of_type) do
      local line = {
        str = prefix(file.type) .. file.name,
        highlight_group = get_highlight_group(file.state),
        file = file,
      }
      table.insert(lines, line)
    end
  end
  table.insert(lines, { str = "", highlight_group = nil, file = nil, })
  table.insert(lines, {
    str = "s = stage/unstage, c = commit, q = quit, a = stage all",
    highlight_group = nil,
    file = nil,
  })
  return lines
end

---@param buf integer
---@param namespace integer
local function refresh_buffer(buf, namespace)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})

  local files, err = parser.retrieve_files()
  if err ~= nil then
    vim.print(err)
    return nil
  end
  buf_lines = get_lines(files)
  for i, line in ipairs(buf_lines) do
    local line_nr = i - 1
    vim.api.nvim_buf_set_lines(buf, line_nr, line_nr, true, {line.str})
    vim.api.nvim_buf_set_extmark(buf, namespace, line_nr, 0, {
      end_col = line.str:len(),
      hl_group = line.highlight_group,
    })
  end
  vim.api.nvim_buf_set_lines(buf, -2, -1, true, {})

  vim.api.nvim_win_set_cursor(0, cursor_pos)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
end

function M.open_status_win()
  local buf = vim.api.nvim_create_buf(false, true)
  local namespace = vim.api.nvim_create_namespace("")
  vim.api.nvim_set_hl(namespace, "staged", { fg = "#26A641" })
  vim.api.nvim_set_hl(namespace, "not_staged", { fg = "#D73A49" })
  vim.api.nvim_set_hl_ns(namespace)

  refresh_buffer(buf, namespace)

  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<CMD>q<CR>', {
    desc = "Quit",
  })
  local toggle_stage_cmd = string.format(
      '<CMD>lua require("gitstatus").toggle_stage_file(%s, %s)<CR>',
      buf,
      namespace
  )
  vim.api.nvim_buf_set_keymap(buf, 'n', 's', toggle_stage_cmd, {
    desc = "Stage/unstage file on current line"
  })

  local stage_all_cmd = string.format(
      '<CMD>lua require("gitstatus").stage_all(%s, %s)<CR>',
      buf,
      namespace
  )
  vim.api.nvim_buf_set_keymap(buf, 'n', 'a', stage_all_cmd, {
    desc = "Stage all changes"
  })

  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = 10,
    col = 60,
    width = 65,
    height = 15,
  })
end

---@param buf integer
---@param namespace integer
function M.toggle_stage_file(buf, namespace)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = buf_lines[row]
  if line.file == nil then
    vim.print("Unable to stage file: invalid line")
    return;
  end
  if line.file.state == FILE_STATE.staged then
    git.unstage_file(line.file.name)
  else
    git.stage_file(line.file.name)
  end
  refresh_buffer(buf, namespace)
end

---@param buf integer
---@param namespace integer
function M.stage_all(buf, namespace)
  git.stage_all()
  refresh_buffer(buf, namespace)
end

return M
