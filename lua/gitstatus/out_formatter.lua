require('gitstatus.line')
local File = require('gitstatus.file')
local StringUtils = require('gitstatus.string_utils')

local M = {}

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
local function file_edit_type_str(file_edit_type)
  return file_edit_type == File.EDIT_TYPE.modified and 'modified:'
    or file_edit_type == File.EDIT_TYPE.added and 'new file:'
    or file_edit_type == File.EDIT_TYPE.deleted and 'deleted:'
    or file_edit_type == File.EDIT_TYPE.renamed and 'renamed:'
    or file_edit_type == File.EDIT_TYPE.file_type_changed and 'typechange:'
    or file_edit_type == File.EDIT_TYPE.copied and 'copied:'
    or file_edit_type == File.EDIT_TYPE.both_deleted and 'both deleted:'
    or file_edit_type == File.EDIT_TYPE.added_by_us and 'added by us:'
    or file_edit_type == File.EDIT_TYPE.deleted_by_them and 'deleted by them:'
    or file_edit_type == File.EDIT_TYPE.added_by_them and 'added by them:'
    or file_edit_type == File.EDIT_TYPE.deleted_by_us and 'deleted by us:'
    or file_edit_type == File.EDIT_TYPE.both_added and 'both added:'
    or file_edit_type == File.EDIT_TYPE.both_modified and 'both modified:'
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
    return file.orig_path .. ' -> ' .. file.path
  end
  return file.path
end

---@return (fun(filepath: string): icon: string, hl_group: string) | nil
local function get_icon_provider()
  local devicons_exists, devicons = pcall(require, 'nvim-web-devicons')
  if devicons_exists then
    return function(filepath)
      local filename = File.filename(filepath)
      return devicons.get_icon(
        filename,
        File.file_extension(filename),
        { default = true }
      )
    end
  end

  local mini_icons_exists, mini_icons = pcall(require, 'mini.icons')
  if mini_icons_exists then
    return function(filepath)
      local filename = File.filename(filepath)
      local file_extension = File.file_extension(filename)
      return mini_icons.get('filetype', file_extension)
    end
  end

  return nil
end

---@param files File[]
---@return integer
local function get_max_edit_type_len(files)
  local max_length = 0
  for _, file in ipairs(files) do
    local edit_type = file_edit_type_str(file.type)
    if #edit_type > max_length then
      max_length = #edit_type
    end
  end
  return max_length
end

---@param file File
---@param icon_provider (fun(filepath: string): icon: string, hl_group: string) | nil
---@param max_edit_type_len integer
---@return Line
local function file_to_line(file, icon_provider, max_edit_type_len)
  ---@type LinePart
  local edit_type = {
    str = file_edit_type_str(file.type),
    hl_group = 'String',
  }

  local min_margin = 4
  local margin_len = max_edit_type_len - #edit_type.str + min_margin
  ---@type LinePart
  local margin = {
    str = string.rep(' ', margin_len),
    hl_group = nil,
  }

  local filename = file_to_name(file)
  local max_filename_len = 50
  ---@type LinePart
  local name = {
    str = StringUtils.truncate_string(filename, max_filename_len),
    hl_group = nil,
  }

  ---@type LinePart
  local icon = nil
  if icon_provider ~= nil then
    local icon_str, hl_group = icon_provider(file.path)
    icon = { str = icon_str .. '  ', hl_group = hl_group }
  end

  ---@type LinePart[]
  local parts = { edit_type, margin, name }
  if icon ~= nil then
    parts = { edit_type, margin, icon, name }
  end

  ---@type Line
  local line = {
    parts = parts,
    file = file,
  }
  return line
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

  local icon_provider = get_icon_provider()
  local max_edit_type_len = get_max_edit_type_len(files)
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
      table.insert(lines, file_to_line(file, icon_provider, max_edit_type_len))
    end
  end
  return lines
end

---@return string[]
function M.make_commit_init_msg()
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
  table.insert(lines, '# Save and close this buffer to confirm your commit')

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
          str = 'Stage/unstage file',
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
          str = 'Commit',
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
          str = 'Open file',
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
