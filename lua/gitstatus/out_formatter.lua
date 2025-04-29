require('gitstatus.line')
local File = require('gitstatus.file')

local M = {}

---@param file_state STATE
---@return string
local function get_highlight_group(file_state)
  return file_state == File.STATE.staged and 'staged' or 'not_staged'
end

---@param files File[]
---@return File[][]
local function split_files_by_state(files)
  ---@type File[][]
  local split_files = { {}, {}, {}, {} }
  for _, file in ipairs(files) do
    table.insert(split_files[file.state + 1], file)
  end
  return split_files
end

---@param file_edit_type EDIT_TYPE?
---@return string
local function prefix(file_edit_type)
  return file_edit_type == File.EDIT_TYPE.modified and 'modified: '
    or file_edit_type == File.EDIT_TYPE.added and 'new file: '
    or file_edit_type == File.EDIT_TYPE.deleted and 'deleted: '
    or file_edit_type == File.EDIT_TYPE.renamed and 'renamed: '
    or file_edit_type == File.EDIT_TYPE.file_type_changed and 'typechange: '
    or file_edit_type == File.EDIT_TYPE.copied and 'copied: '
    or file_edit_type == File.EDIT_TYPE.both_deleted and 'both deleted: '
    or file_edit_type == File.EDIT_TYPE.added_by_us and 'added by us: '
    or file_edit_type == File.EDIT_TYPE.deleted_by_them and 'deleted by them: '
    or file_edit_type == File.EDIT_TYPE.added_by_them and 'added by them: '
    or file_edit_type == File.EDIT_TYPE.deleted_by_us and 'deleted by us: '
    or file_edit_type == File.EDIT_TYPE.both_added and 'both added: '
    or file_edit_type == File.EDIT_TYPE.both_modified and 'both modified: '
    or ''
end

---@param state STATE
---@return string
local function file_state_name(state)
  return state == File.STATE.staged and 'Staged:'
    or state == File.STATE.unmerged and 'Unmerged paths:'
    or state == File.STATE.not_staged and 'Not staged:'
    or state == File.STATE.untracked and 'Untracked:'
    or ''
end

---@param file File
---@return string
local function file_to_name(file)
  if file.orig_path ~= nil then
    return prefix(file.type) .. file.orig_path .. ' -> ' .. file.path
  end
  return prefix(file.type) .. file.path
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

  local file_table = split_files_by_state(files)
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
            str = file_state_name(i - 1),
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
            str = file_to_name(file),
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

---@param state STATE
---@return string
local function file_state_name_in_commit_msg(state)
  assert(state ~= File.STATE.unmerged)
  return state == File.STATE.staged and '# Changes to be commited:'
    or state == File.STATE.not_staged and '# Changes not staged for commit:'
    or state == File.STATE.untracked and '# Untracked files:'
    or ''
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

  local file_table = split_files_by_state(files)
  for i, files_of_type in ipairs(file_table) do
    if #files_of_type > 0 then
      table.insert(lines, '#')
      table.insert(lines, file_state_name_in_commit_msg(i))
    end
    for _, file in ipairs(files_of_type) do
      table.insert(lines, '#\t' .. file_to_name(file))
    end
  end
  table.insert(lines, '#')
  return lines
end

---@return Line[]
function M.make_help_window_msg()
  ---@type Line[]
  return {
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
end

return M
