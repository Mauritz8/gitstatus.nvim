local parser = require("parser")
local git_actions = require("git_actions")

local M = {}

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


---@class Line
---@field str string
---@field highlight_group string
Line = {}

---@param files File[]
---@return Line[]
local function get_lines(files)
  local lines = {}

  local branch = parser.branch()
  if branch then
    table.insert(lines, {
      str = "Branch: " .. branch,
      highlight_group = nil,
    })
  end

  if #files == 0 then
    if #lines > 0 then
      table.insert(lines, { str = ""; highlight_group = nil })
    end
    table.insert(lines, {
      str = "nothing to commit, working tree clean",
      highlight_group = nil
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
        table.insert(lines, { str = ""; highlight_group = nil })
      end
      table.insert(lines, { str = name(i); highlight_group = nil })
    end
    for _, file in ipairs(files_of_type) do
      local line = {
        str = prefix(file.type) .. file.name,
        highlight_group = highlight_group(file.state),
      }
      table.insert(lines, line)
    end
  end
  return lines
end

---@param buf integer
local function set_content(buf)
  local ns_id = vim.api.nvim_create_namespace("")
  vim.api.nvim_set_hl(ns_id, "staged", { fg = "#26A641" })
  vim.api.nvim_set_hl(ns_id, "not_staged", { fg = "#D73A49" })
  vim.api.nvim_set_hl_ns(ns_id)

  local files = parser.retrieve_files()
  local lines = get_lines(files)
  for i, line in ipairs(lines) do
    local line_nr = i - 1
    vim.api.nvim_buf_set_lines(buf, line_nr, line_nr, true, {line.str})
    vim.api.nvim_buf_set_extmark(buf, ns_id, line_nr, 0, {
      end_col = line.str:len(),
      hl_group = line.highlight_group,
    })
  end
  vim.api.nvim_buf_set_lines(buf, -2, -1, true, {})
end

function M.open_status_win()
  local buf = vim.api.nvim_create_buf(false, true)
  set_content(buf)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<CMD>q<CR>', {})
  vim.api.nvim_buf_set_keymap(buf, 'n', 's',
      '<CMD>lua require("gitstatus").stage_file()<CR>', {})

  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = 10,
    col = 60,
    width = 65,
    height = 15,
  })
end

--- TODO: make staging branch name line invalid
---@param line string
---@return string?
local function file_on_line(line)
  local invalid_lines = {
    "",
    "Staged:",
    "Not staged:",
    "Untracked:",
  }
  for _, invalid_line in ipairs(invalid_lines) do
    if line == invalid_line then
      return nil
    end
  end

  local i = line:find(":")
  if i == nil then
    return line
  end
  local file_start = i + 2
  if file_start >= line:len() then
    return nil
  end
  return line:sub(file_start)
end

function M.stage_file()
  local line = vim.api.nvim_get_current_line()
  local file = file_on_line(line)
  if file == nil then
    vim.print("Unable to stage file: invalid line")
  else
    git_actions.stage_file(file)
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
    set_content(buf)
  end
end

return M
