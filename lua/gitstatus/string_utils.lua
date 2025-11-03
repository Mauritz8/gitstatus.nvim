local M = {}

---@param str string
---@param delim string
---@return string[]
function M.split(str, delim)
  if #str == 0 then
    return {}
  end

  local matches = {}
  local match_start = 1
  while true do
    local delim_start, delim_end = str:find(delim, match_start)
    if delim_start ~= nil and delim_end ~= nil then
      table.insert(matches, str:sub(match_start, delim_start - 1))
      match_start = delim_end + 1
    else
      local remaining_str = str:sub(match_start)
      if #remaining_str > 0 then
        table.insert(matches, remaining_str)
      end
      break
    end
  end
  return matches
end

---@param str string
---@return string
function M.strip_trailing_newline(str)
  local len = #str
  if str:sub(len) == '\n' then
    return str:sub(1, len - 1)
  end
  return str
end

return M
