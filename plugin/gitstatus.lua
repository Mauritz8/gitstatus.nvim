vim.api.nvim_buf_create_user_command(0, 'Gitstatus', function()
  require('gitstatus').open_status_win()
end, {})
