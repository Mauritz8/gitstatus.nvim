local M = {}

function M.open_status_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, {'hello', 'goodbye'})
  vim.api.nvim_open_win(buf, true, {
    split = 'left',
    width = 50,
  })
end

return M
