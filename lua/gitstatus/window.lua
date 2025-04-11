local M = {}

---@param lines Line[]
---@return integer
local function max_line_length(lines)
  local max_length = 0
  for _, line in ipairs(lines) do
    local line_len = line.str:len()
    if line_len > max_length then
      max_length = line_len
    end
  end
  return max_length
end

---@param lines Line[]
---@return integer
function M.width(lines, numberwidth)
  local margin = 5
  return max_line_length(lines) + numberwidth + margin
end

---@param lines Line[]
---@return integer
function M.height(lines)
  return #lines
end

---@param parent_win_height integer
---@param win_height integer
---@return integer
function M.row(parent_win_height, win_height)
  return ((parent_win_height - win_height) / 2)
end

---@param parent_win_width integer
---@param win_width integer
---@return integer
function M.column(parent_win_width, win_width)
  return (parent_win_width - win_width) / 2
end

return M
