local M = {}

---@enum STATUS
M.STATUS = {
  unmodified = 0,
  modified = 1,
  file_type_changed = 2,
  added = 3,
  deleted = 4,
  renamed = 5,
  copied = 6,
  updated_but_unmerged = 7,
}

---@class StatusCode
---@field x STATUS
---@field y STATUS

-- https://git-scm.com/docs/git-status
---@class Path
---@field path string
---@field orig_path string?
---@field status_code StatusCode?
---@field unmerged boolean

return M
