local M = {}

---@param lines string[]
---@return integer
local function max_line_length(lines)
  local max_length = 0
  for _, line in ipairs(lines) do
    local line_len = line:len()
    if line_len > max_length then
      max_length = line_len
    end
  end
  return max_length
end

---@param lines string[]
---@param numberwidth integer
---@param parent_win_width number
---@return number
function M.width(lines, numberwidth, parent_win_width)
  local margin = 5
  local width = max_line_length(lines) + numberwidth + margin
  return width < parent_win_width and width or parent_win_width
end

---@param lines string[]
---@param parent_win_height number
---@return number
function M.height(lines, parent_win_height)
  local len = #lines
  return len < parent_win_height and len or parent_win_height
end

---@param parent_win_height number
---@param win_height number
---@return number
function M.row(parent_win_height, win_height)
  return (parent_win_height - win_height) / 2
end

---@param parent_win_width number
---@param win_width number
---@return number
function M.column(parent_win_width, win_width)
  return (parent_win_width - win_width) / 2
end

return M
