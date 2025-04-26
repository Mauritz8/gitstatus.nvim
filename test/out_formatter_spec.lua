local file = require('gitstatus.file')
local out_formatter = require('gitstatus.out_formatter')

describe('out_formatter.lua', function()
  describe('format_out_lines', function()
    it('no files', function()
      local branch = 'main'
      ---@type File[]
      local files = {}
      local lines = out_formatter.format_out_lines(branch, files)
      ---@type Line[]
      local expected = {
        {
          parts = {
            {
              str = 'Branch: ',
              hl_group = 'Label',
            },
            {
              str = 'main',
              hl_group = 'Function',
            },
          },
          file = nil,
        },
        {
          parts = {
            {
              str = 'Help: ',
              hl_group = 'Label',
            },
            {
              str = '?',
              hl_group = 'Function',
            },
          },
          file = nil,
        },
        {
          parts = {
            {
              str = '',
              hl_group = nil,
            },
          },
          file = nil,
        },
        {
          parts = {
            {
              str = 'nothing to commit, working tree clean',
              hl_group = nil,
            },
          },
          file = nil,
        },
      }
      assert.are_same(expected, lines)
    end)
    it('files with all states', function()
      local branch = 'main'
      ---@type File[]
      local files = {
        {
          path = 'file1.txt',
          state = file.STATE.staged,
          type = file.EDIT_TYPE.modified,
        },
        {
          path = 'file2.txt',
          state = file.STATE.not_staged,
          type = file.EDIT_TYPE.deleted,
        },
        {
          path = 'file3.txt',
          state = file.STATE.untracked,
          type = nil,
        },
        {
          path = 'file5.txt',
          orig_path = 'file4.txt',
          state = file.STATE.staged,
          type = file.EDIT_TYPE.renamed,
        },
      }
      local lines = out_formatter.format_out_lines(branch, files)
      ---@type Line[]
      local expected = {
        {
          parts = {
            {
              str = 'Branch: ',
              hl_group = 'Label',
            },
            {
              str = 'main',
              hl_group = 'Function',
            },
          },
          file = nil,
        },
        {
          parts = {
            {
              str = 'Help: ',
              hl_group = 'Label',
            },
            {
              str = '?',
              hl_group = 'Function',
            },
          },
          file = nil,
        },
        {
          parts = {
            {
              str = '',
              hl_group = nil,
            },
          },
          file = nil,
        },
        {
          parts = {
            {
              str = 'Staged:',
              hl_group = nil,
            },
          },
          file = nil,
        },
        {
          parts = {
            {
              str = 'modified: file1.txt',
              hl_group = 'staged',
            },
          },
          file = files[1],
        },
        {
          parts = {
            {
              str = 'renamed: file4.txt -> file5.txt',
              hl_group = 'staged',
            },
          },
          file = files[4],
        },
        {
          parts = {
            {
              str = '',
              hl_group = nil,
            },
          },
          file = nil,
        },
        {
          parts = {
            {
              str = 'Not staged:',
              hl_group = nil,
            },
          },
          file = nil,
        },
        {
          parts = {
            {
              str = 'deleted: file2.txt',
              hl_group = 'not_staged',
            },
          },
          file = files[2],
        },
        {
          parts = {
            {
              str = '',
              hl_group = nil,
            },
          },
          file = nil,
        },
        {
          parts = {
            {
              str = 'Untracked:',
              hl_group = nil,
            },
          },
          file = nil,
        },
        {
          parts = {
            {
              str = 'file3.txt',
              hl_group = 'not_staged',
            },
          },
          file = files[3],
        },
      }
      assert.are_same(expected, lines)
    end)
  end)
end)
