require('gitstatus.line')
local File = require('gitstatus.file')

local M = {}

---@param file_edit_type FILE_EDIT_TYPE
---@return string
local function prefix(file_edit_type)
  return file_edit_type == File.FILE_EDIT_TYPE.modified and 'modified: '
    or file_edit_type == File.FILE_EDIT_TYPE.new and 'new file: '
    or file_edit_type == File.FILE_EDIT_TYPE.deleted and 'deleted: '
    or file_edit_type == File.FILE_EDIT_TYPE.renamed and 'renamed: '
    or file_edit_type == File.FILE_EDIT_TYPE.file_type_changed and 'typechange: '
    or file_edit_type == File.FILE_EDIT_TYPE.copied and 'copied: '
    or ''
end

---@param file_state FILE_STATE
---@return string
local function get_highlight_group(file_state)
  return file_state == File.FILE_STATE.staged and 'staged' or 'not_staged'
end

---@param files File[]
---@return File[], File[], File[]
local function split_files_by_state(files)
  local staged = {}
  local not_staged = {}
  local untracked = {}
  for _, file in ipairs(files) do
    if file.state == File.FILE_STATE.staged then
      table.insert(staged, file)
    elseif file.state == File.FILE_STATE.not_staged then
      table.insert(not_staged, file)
    elseif file.state == File.FILE_STATE.untracked then
      table.insert(untracked, file)
    end
  end
  return staged, not_staged, untracked
end

---@param branch string
---@param files File[]
---@return Line[]
function M.format_out_lines(branch, files)
  ---@type Line[]
  local lines = {}

  table.insert(lines, {
    parts = {
      {
        str = 'Branch: ',
        hl_group = 'Label',
      },
      {
        str = branch,
        hl_group = 'Function',
      },
    },
    file = nil,
  })
  table.insert(lines, {
    parts = {
      {
        str = 'Help: ',
        hl_group = 'Label',
      },
      {
        str = '?',
        hl_group = 'Function',
      },
    },
    file = nil,
  })

  if #files == 0 then
    table.insert(lines, {
      parts = {
        {
          str = '',
          hl_group = nil,
        },
      },
      file = nil,
    })
    table.insert(lines, {
      parts = {
        {
          str = 'nothing to commit, working tree clean',
          hl_group = nil,
        },
      },
      file = nil,
    })
  end

  local staged, not_staged, untracked = split_files_by_state(files)
  local file_table = { staged, not_staged, untracked }
  local name = function(i)
    return i == 1 and 'Staged:' or i == 2 and 'Not staged:' or 'Untracked:'
  end
  for i, files_of_type in ipairs(file_table) do
    if #files_of_type > 0 then
      table.insert(lines, {
        parts = {
          {
            str = '',
            hl_group = nil,
          },
        },
        file = nil,
      })
      table.insert(lines, {
        parts = {
          {
            str = name(i),
            hl_group = nil,
          },
        },
        file = nil,
      })
    end
    for _, file in ipairs(files_of_type) do
      local line = {
        parts = {
          {
            str = prefix(file.type) .. file.name,
            hl_group = get_highlight_group(file.state),
          },
        },
        file = file,
      }
      table.insert(lines, line)
    end
  end
  return lines
end

---@param branch string
---@param files File[]
---@return string[]
function M.make_commit_init_msg(branch, files)
  ---@type string[]
  local lines = {}
  table.insert(lines, '')
  table.insert(
    lines,
    '# Please enter the commit message for your changes. Lines starting'
  )
  table.insert(
    lines,
    "# with '#' will be ignored, and an empty message aborts the commit."
  )
  table.insert(lines, '#')
  table.insert(lines, '# On branch ' .. branch)

  local staged, not_staged, untracked = split_files_by_state(files)
  local file_table = { staged, not_staged, untracked }
  local name = function(i)
    return i == 1 and '# Changes to be commited:'
      or i == 2 and '# Changes not staged for commit:'
      or '# Untracked files:'
  end
  for i, files_of_type in ipairs(file_table) do
    if #files_of_type > 0 then
      table.insert(lines, '#')
      table.insert(lines, name(i))
    end
    for _, file in ipairs(files_of_type) do
      table.insert(lines, '#\t' .. prefix(file.type) .. file.name)
    end
  end
  table.insert(lines, '#')
  return lines
end

return M
