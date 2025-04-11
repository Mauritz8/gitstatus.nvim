local File = require('gitstatus.file')

local M = {}

---@class Line
---@field str string
---@field highlight_group string?
---@field file File?
Line = {}

---@param lines Line[]
---@param current_line_index integer
function M.next_file_index(lines, current_line_index)
  for i = current_line_index + 1, #lines do
    local line = lines[i]
    if line.file ~= nil then
      return i
    end
  end
  return current_line_index
end

---@param lines Line[]
---@param current_line_index integer
function M.prev_file_index(lines, current_line_index)
  for i = current_line_index - 1, 1, -1 do
    local line = lines[i]
    if line.file ~= nil then
      return i
    end
  end
  return current_line_index
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


return M
