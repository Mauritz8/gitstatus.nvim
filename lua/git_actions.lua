local M = {}

---@param file string
function M.stage_file(file)
  local obj = vim.system({'git', 'add', file}, { text = true }):wait()
  if obj.code ~= 0 then
    vim.print("Unable to stage file:", obj.stderr)
  else
    vim.print(("Successfully staged %s!"):format(file))
  end
end

return M
