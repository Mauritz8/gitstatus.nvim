local Path = require('gitstatus.path')
local StringUtils = require('gitstatus.string_utils')

local M = {}

---@enum STATE
M.STATE = {
  staged = 0,
  unmerged = 1,
  not_staged = 2,
  untracked = 3,
}

---@enum EDIT_TYPE
M.EDIT_TYPE = {
  modified = 0,
  file_type_changed = 1,
  added = 2,
  deleted = 3,
  renamed = 4,
  copied = 5,
  both_deleted = 6,
  added_by_us = 7,
  deleted_by_them = 8,
  added_by_them = 9,
  deleted_by_us = 10,
  both_added = 11,
  both_modified = 12,
}

---@class File
---@field path string
---@field orig_path string?
---@field state STATE
---@field type? EDIT_TYPE

---@param filepath string
---@return string
function M.filename(filepath)
  local parts = StringUtils.split(filepath, '/')
  return parts[#parts]
end

---@param filename string
---@return string?
function M.fileExtension(filename)
  local parts = StringUtils.split(filename, '%.')
  if #parts < 2 then
    return nil
  end
  local is_hidden_file_without_file_extension = #parts == 2 and parts[1] == ''
  if is_hidden_file_without_file_extension then
    return nil
  end
  return parts[#parts]
end

---@param file1 File
---@param file2 File
---@return boolean
function M.equal(file1, file2)
  return file1.path == file2.path
    and file1.orig_path == file2.orig_path
    and file1.state == file2.state
    and file1.type == file2.type
end

---@param status STATUS
---@return EDIT_TYPE?
local function path_status_to_edit_type(status)
  return status == Path.STATUS.modified and M.EDIT_TYPE.modified
    or status == Path.STATUS.file_type_changed and M.EDIT_TYPE.file_type_changed
    or status == Path.STATUS.added and M.EDIT_TYPE.added
    or status == Path.STATUS.deleted and M.EDIT_TYPE.deleted
    or status == Path.STATUS.renamed and M.EDIT_TYPE.renamed
    or status == Path.STATUS.copied and M.EDIT_TYPE.copied
    or nil
end

---@param status_code StatusCode
---@return EDIT_TYPE?
local function unmerged_path_edit_type(status_code)
  if
    status_code.x == Path.STATUS.deleted
    and status_code.y == Path.STATUS.deleted
  then
    return M.EDIT_TYPE.both_deleted
  elseif
    status_code.x == Path.STATUS.added
    and status_code.y == Path.STATUS.updated_but_unmerged
  then
    return M.EDIT_TYPE.added_by_us
  elseif
    status_code.x == Path.STATUS.updated_but_unmerged
    and status_code.y == Path.STATUS.deleted
  then
    return M.EDIT_TYPE.deleted_by_them
  elseif
    status_code.x == Path.STATUS.updated_but_unmerged
    and status_code.y == Path.STATUS.added
  then
    return M.EDIT_TYPE.added_by_them
  elseif
    status_code.x == Path.STATUS.deleted
    and status_code.y == Path.STATUS.updated_but_unmerged
  then
    return M.EDIT_TYPE.deleted_by_us
  elseif
    status_code.x == Path.STATUS.added
    and status_code.y == Path.STATUS.added
  then
    return M.EDIT_TYPE.both_added
  elseif
    status_code.x == Path.STATUS.updated_but_unmerged
    and status_code.y == Path.STATUS.updated_but_unmerged
  then
    return M.EDIT_TYPE.both_modified
  else
    return nil
  end
end

---@param path Path
---@return File[]
local function path_to_files(path)
  if path.status_code == nil then
    ---@type File[]
    return {
      {
        path = path.path,
        orig_path = path.orig_path,
        state = M.STATE.untracked,
        type = nil,
      },
    }
  end

  if path.unmerged then
    ---@type File[]
    return {
      {
        path = path.path,
        orig_path = path.orig_path,
        state = M.STATE.unmerged,
        type = unmerged_path_edit_type(path.status_code),
      },
    }
  end

  ---@type File[]
  local files = {}
  if path.status_code.x ~= Path.STATUS.unmodified then
    local orig_path = path.status_code.x == Path.STATUS.renamed
        and path.orig_path
      or nil
    ---@type File
    local file = {
      path = path.path,
      orig_path = orig_path,
      state = M.STATE.staged,
      type = path_status_to_edit_type(path.status_code.x),
    }
    table.insert(files, file)
  end

  if path.status_code.y ~= Path.STATUS.unmodified then
    local orig_path = path.status_code.y == Path.STATUS.renamed
        and path.orig_path
      or nil
    ---@type File
    local file = {
      path = path.path,
      orig_path = orig_path,
      state = M.STATE.not_staged,
      type = path_status_to_edit_type(path.status_code.y),
    }
    table.insert(files, file)
  end

  return files
end

---@param paths Path[]
---@return File[]
function M.paths_to_files(paths)
  ---@type File[]
  local files = {}
  for _, path in ipairs(paths) do
    local path_files = path_to_files(path)
    for _, file in ipairs(path_files) do
      table.insert(files, file)
    end
  end
  return files
end

return M
