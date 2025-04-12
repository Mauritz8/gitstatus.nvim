# gitstatus.nvim

A Neovim plugin for managing Git from the editor. Shows an interactive status window with support for staging, unstaging, and committing files.

TODO: Add a demo GIF here

## Installation
Install with your favorite plugin manager. For example, using [Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ 'Mauritz8/gitstatus.nvim' }
```

Or with [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use 'Mauritz8/gitstatus.nvim'
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
- `<CR>` (`Enter`) - Open file on the current line
- `q` – Close window
