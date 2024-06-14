local M = {}

local function split(str, delim)
  local lines = {}
  for line in string.gmatch(str, '[^' .. delim .. ']+') do
    table.insert(lines, line)
  end
  return lines
end

local function execute_cmd(cmd)
  local handle = io.popen(cmd)
  assert(handle, 'cannot execute command "' .. cmd .. '"')

  local output = handle:read('*a')
  handle:close()

  return output
end

function M.open_status_win()
  local git_status = execute_cmd('git status -s')
  local lines = split(git_status, '\n')

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  vim.api.nvim_open_win(buf, true, {
    split = 'left',
    width = 50,
  })
end

return M
