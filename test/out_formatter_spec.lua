local file = require('gitstatus.file')
local out_formatter = require('gitstatus.out_formatter')

describe('out_formatter.lua', function()
  describe('format_out_lines', function()
    it('no files', function()
      local branch = 'main'
      local files = {}
      local lines = out_formatter.format_out_lines(branch, files)
      local expected = {
        {
          str = 'Branch: main',
          highlight_group = nil,
          file = nil,
        },
        {
          str = '',
          highlight_group = nil,
          file = nil,
        },
        {
          str = 'nothing to commit, working tree clean',
          highlight_group = nil,
          file = nil,
        },
      }
      assert.are_same(expected, lines)
    end)
    it('files with all states', function()
      local branch = 'main'
      local files = {
        {
          name = 'file1.txt',
          state = file.FILE_STATE.staged,
          type = file.FILE_EDIT_TYPE.modified,
        },
        {
          name = 'file2.txt',
          state = file.FILE_STATE.not_staged,
          type = file.FILE_EDIT_TYPE.deleted,
        },
        {
          name = 'file3.txt',
          state = file.FILE_STATE.untracked,
          type = file.FILE_EDIT_TYPE.none,
        },
        {
          name = 'file4.txt',
          state = file.FILE_STATE.staged,
          type = file.FILE_EDIT_TYPE.new,
        },
      }
      local lines = out_formatter.format_out_lines(branch, files)
      local expected = {
        {
          str = 'Branch: main',
          highlight_group = nil,
          file = nil,
        },
        {
          str = '',
          highlight_group = nil,
          file = nil,
        },
        {
          str = 'Staged:',
          highlight_group = nil,
          file = nil,
        },
        {
          str = 'modified: file1.txt',
          highlight_group = 'staged',
          file = files[1],
        },
        {
          str = 'new file: file4.txt',
          highlight_group = 'staged',
          file = files[4],
        },
        {
          str = '',
          highlight_group = nil,
          file = nil,
        },
        {
          str = 'Not staged:',
          highlight_group = nil,
          file = nil,
        },
        {
          str = 'deleted: file2.txt',
          highlight_group = 'not_staged',
          file = files[2],
        },
        {
          str = '',
          highlight_group = nil,
          file = nil,
        },
        {
          str = 'Untracked:',
          highlight_group = nil,
          file = nil,
        },
        {
          str = 'file3.txt',
          highlight_group = 'not_staged',
          file = files[3],
        },
        {
          str = '',
          highlight_group = nil,
          file = nil,
        },
        {
          str = 's = stage/unstage, a = stage all, c = commit, Enter = open file, q = quit',
          highlight_group = nil,
          file = nil,
        },
      }
      assert.are_same(expected, lines)
    end)
  end)
end)
