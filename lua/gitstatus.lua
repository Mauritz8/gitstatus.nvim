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

---@param buf integer
---@param i integer
---@param file File
local function set_line(buf, i, file)
  local line_nr = i - 1
  local line = prefix(file.type) .. file.name
  vim.api.nvim_buf_set_lines(buf, line_nr, line_nr, true, {line})

  local ns_id = vim.api.nvim_create_namespace("")
  local hl_group = highlight_group(file.state)
  vim.api.nvim_buf_set_extmark(buf, ns_id, line_nr, 0, {
    end_col = string.len(line),
    hl_group = hl_group,
  })
end

function M.open_status_win()
  local buf = vim.api.nvim_create_buf(false, true)

  local files = parser.retrieve_files()
  if #files == 0 then
    local content = "nothing to commit, working tree clean"
    vim.api.nvim_buf_set_lines(buf, 0, 0, true, {content})
  else
    for i, file in pairs(files) do
      set_line(buf, i, file)
    end
  end
  vim.api.nvim_buf_set_lines(buf, -2, -1, true, {})

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
