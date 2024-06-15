vim.api.nvim_create_user_command('Gitstatus', function()
  require('gitstatus').toggle_status_win()
end, {})
