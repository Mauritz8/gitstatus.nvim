vim.api.nvim_create_user_command('Gitstatus', function()
  require('gitstatus').open_status_win()
end, {})
