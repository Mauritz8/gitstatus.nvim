local File = require('gitstatus.file')

local M = {}

---@class LinePart
---@field str string
---@field hl_group string?

---@class Line
---@field parts LinePart[]
---@field file File?

---@param lines Line[]
---@param current_line_index integer
---@return integer?
function M.next_file_index(lines, current_line_index)
  for i = current_line_index + 1, #lines do
    local line = lines[i]
    if line.file ~= nil then
      return i
    end
  end
  return nil
end

---@param lines Line[]
---@param current_line_index integer
---@return integer?
function M.prev_file_index(lines, current_line_index)
  for i = current_line_index - 1, 1, -1 do
    local line = lines[i]
    if line.file ~= nil then
      return i
    end
  end
  return nil
end

---@param lines Line[]
---@param file File
---@return integer?
function M.line_index_of_file(lines, file)
  for i, line in ipairs(lines) do
    if line.file ~= nil and File.equal(line.file, file) then
      return i
    end
  end
  return nil
end

---@param lines Line[]
---@return integer
function M.staged_files(lines)
  local count = 0
  for _, line in ipairs(lines) do
    if line.file and line.file.state == File.STATE.staged then
      count = count + 1
    end
  end
  return count
end

---@param lines Line[]
---@return integer
function M.unmerged_files(lines)
  local count = 0
  for _, line in ipairs(lines) do
    if line.file and line.file.state == File.STATE.unmerged then
      count = count + 1
    end
  end
  return count
end

---@param lines Line[]
---@return string[]
function M.get_lines_strings(lines)
  ---@type string[]
  local strings = {}
  for _, line in ipairs(lines) do
    local str = ''
    for _, part in ipairs(line.parts) do
      str = str .. part.str
    end
    table.insert(strings, str)
  end
  return strings
end

return M
