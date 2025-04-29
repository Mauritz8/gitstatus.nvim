local Path = require('gitstatus.path')

local M = {}

---@enum STATE
M.STATE = {
  staged = 0,
  not_staged = 1,
  untracked = 2,
}

---@enum EDIT_TYPE
M.EDIT_TYPE = {
  modified = 0,
  file_type_changed = 1,
  added = 2,
  deleted = 3,
  renamed = 4,
  copied = 5,
}

---@class File
---@field path string
---@field orig_path string?
---@field state STATE
---@field type? EDIT_TYPE

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
  assert(status ~= Path.STATUS.unmodified)
  -- TODO: How to handle merge states that are not supported yet?
  assert(status ~= Path.STATUS.updated_but_unmerged)
  return status == Path.STATUS.modified and M.EDIT_TYPE.modified
    or status == Path.STATUS.file_type_changed and M.EDIT_TYPE.file_type_changed
    or status == Path.STATUS.added and M.EDIT_TYPE.added
    or status == Path.STATUS.deleted and M.EDIT_TYPE.deleted
    or status == Path.STATUS.renamed and M.EDIT_TYPE.renamed
    or status == Path.STATUS.copied and M.EDIT_TYPE.copied
    or nil
end

---@param path Path
---@return File[]
local function path_to_files(path)
  ---@type File[]
  local files = {}

  if path.status_code == nil then
    ---@type File
    local file = {
      path = path.path,
      orig_path = path.orig_path,
      state = M.STATE.untracked,
      type = nil,
    }
    table.insert(files, file)
    return files
  end

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
