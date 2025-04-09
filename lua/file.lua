---@enum FILE_STATE
FILE_STATE = {
  staged = 0,
  not_staged = 1,
  untracked = 2
}

---@enum FILE_EDIT_TYPE
FILE_EDIT_TYPE = {
  modified = 0,
  new = 1,
  deleted = 2,
  renamed = 3,
  none = 4,
}

---@class File
---@field name string
---@field state FILE_STATE
---@field type FILE_EDIT_TYPE
File = {}
