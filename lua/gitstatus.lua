local parser = require("parser")

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
  return file_state == FILE_STATE.staged and 'Added' or 'Removed'
end

---@param files File[]
---@return [File[], File[], File[]]
local function split_files_by_state(files)
  local file_table = {}
  file_table["Staged:"] = {}
  file_table["Not staged:"] = {}
  file_table["Untracked:"] = {}
  for _, file in ipairs(files) do
    if file.state == FILE_STATE.staged then
      table.insert(file_table["Staged:"], file)
    elseif file.state == FILE_STATE.not_staged then
      table.insert(file_table["Not staged:"], file)
    elseif file.state == FILE_STATE.untracked then
      table.insert(file_table["Untracked:"], file)
    end
  end
  return file_table
end


---@class Line
---@field str string
---@field highlight_group string
Line = {}

---@param files File[]
---@return Line[]
local function get_lines(files)
  if #files == 0 then
    return {{
      str = "nothing to commit, working tree clean",
      highlight_group = nil
    }}
  end

  local lines = {}
  local file_table = split_files_by_state(files)
  for name, files_of_type in pairs(file_table) do
    if #files_of_type > 0 then
      table.insert(lines, { str = name; highlight_group = nil })
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
