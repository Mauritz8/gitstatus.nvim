local M = {}

function M.open_status_win()
  local win_config = {
    split = 'left',
    width = 50,
  }
  vim.api.nvim_open_win(0, true, win_config);
end

return M
