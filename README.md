# gitstatus.nvim

A Neovim plugin for managing Git from the editor. Shows an interactive status window with support for staging, unstaging, and committing files.

https://github.com/user-attachments/assets/e7ce741c-8105-4686-b610-3b05dcde5931

## Installation
Install with your favorite plugin manager. For example, using [Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'Mauritz8/gitstatus.nvim',
  -- optional dependencies
  dependencies = {
    'nvim-tree/nvim-web-devicons', -- displays filetype icons
    -- 'nvim-mini/mini.icons' -- use mini.icons instead if you prefer
    'rcarriga/nvim-notify', -- displays nice notifications
  },
}
```

Or with [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'Mauritz8/gitstatus.nvim',
  -- optional dependencies
  requires = {
    'nvim-tree/nvim-web-devicons', -- displays filetype icons
    -- 'nvim-mini/mini.icons' -- use mini.icons instead if you prefer
    'rcarriga/nvim-notify', -- displays nice notifications
  },
}
```

## Usage

Open the Git status window with `:Gitstatus`. For quick access, set up a mapping:

``` lua
vim.keymap.set('n', '<leader>s', vim.cmd.Gitstatus)
```

While inside the Git status window:
- `s` – Stage/unstage the file on the current line
- `a` – Stage all changes
- `c` – Open commit prompt
- `o` - Open file on the current line
- `q` – Close window
