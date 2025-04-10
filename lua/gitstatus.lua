local parser = require('gitstatus.parser')
local git = require('gitstatus.git')

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
---@return Line[], string?
local function get_lines(files)
  local lines = {}

  local branch, err = parser.branch()
  if err ~= nil then
    return {}, err
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
    return lines, nil
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
      table.insert(lines, { str = name(i), highlight_group = nil, file = nil, })
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
---@return string?
local function refresh_buffer(buf, namespace)
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})

  local files, err = parser.retrieve_files()
  if err ~= nil then
    return err
  end
  local lines, err2 = get_lines(files)
  if err2 ~= nil then
    return err2
  end
  buf_lines = lines
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

  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = 10,
    col = 60,
    width = 65,
    height = 15,
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
