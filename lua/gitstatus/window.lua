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
---@param parent_win_width number
---@return number
function M.width(lines, numberwidth, parent_win_width)
  local margin = 5
  local width = max_line_length(lines) + numberwidth + margin
  if width > parent_win_width then
    return parent_win_width
  else
    return width
  end
end

---@param lines Line[]
---@param parent_win_height number
---@return number
function M.height(lines, parent_win_height)
  local len = #lines
  if len > parent_win_height then
    return parent_win_height
  else
    return len
  end
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
