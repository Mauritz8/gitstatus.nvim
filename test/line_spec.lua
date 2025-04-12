local File = require('gitstatus.file')
local line = require('gitstatus.line')

local test_file = {
  name = '',
  state = File.FILE_STATE.staged,
  type = File.FILE_EDIT_TYPE.modified,
}

describe('line.lua', function()
  describe('next_file_index', function()
    it('has next file', function()
      local lines = {
        { str = '', file = nil },
        { str = '', file = test_file },
        { str = '', file = nil },
        { str = '', file = test_file },
        { str = '', file = nil },
      }
      local next_file_index = line.next_file_index(lines, 2)
      assert.equal(4, next_file_index)
    end)
    it('on last file', function()
      local lines = {
        { str = '', file = nil },
        { str = '', file = test_file },
        { str = '', file = nil },
        { str = '', file = test_file },
        { str = '', file = nil },
      }
      local next_file_index = line.next_file_index(lines, 4)
      assert.equal(nil, next_file_index)
    end)
  end)
  describe('prev_file_index', function()
    it('has previous file', function()
      local lines = {
        { str = '', file = nil },
        { str = '', file = test_file },
        { str = '', file = nil },
        { str = '', file = test_file },
        { str = '', file = nil },
      }
      local prev_file_index = line.prev_file_index(lines, 4)
      assert.equal(2, prev_file_index)
    end)
    it('on first file', function()
      local lines = {
        { str = '', file = nil },
        { str = '', file = test_file },
        { str = '', file = nil },
        { str = '', file = test_file },
        { str = '', file = nil },
      }
      local prev_file_index = line.prev_file_index(lines, 2)
      assert.equal(nil, prev_file_index)
    end)
  end)
  describe('line_index_of_file', function()
    it('file exists', function()
      local lines = {
        {
          str = '',
          file = {
            name = 'a',
          },
        },
        {
          str = '',
          file = {
            name = 'b',
          },
        },
        {
          str = '',
          file = {
            name = 'c',
          },
        },
      }
      local file = {
        name = 'b',
      }
      local line_index = line.line_index_of_file(lines, file)
      assert.equal(2, line_index)
    end)
    it('file does not exist', function()
      local file = {
        name = 'd',
      }
      local lines = {
        {
          str = '',
          file = {
            name = 'a',
          },
        },
        {
          str = '',
          file = {
            name = 'b',
          },
        },
        {
          str = '',
          file = {
            name = 'c',
          },
        },
      }
      local line_index = line.line_index_of_file(lines, file)
      assert.equal(nil, line_index)
    end)
  end)
  describe('staged_files', function()
    it('multiple staged files', function()
      local lines = {
        {
          str = '',
          file = {
            name = 'a',
            state = File.FILE_STATE.staged,
          },
        },
        {
          str = '',
          file = {
            name = 'b',
            state = File.FILE_STATE.untracked,
          },
        },
        {
          str = '',
          file = {
            name = 'c',
            state = File.FILE_STATE.not_staged,
          },
        },
        {
          str = '',
          file = {
            name = 'd',
            state = File.FILE_STATE.staged,
          },
        },
      }
      assert.equal(2, line.staged_files(lines))
    end)
    it('no staged files', function()
      local lines = {
        {
          str = '',
          file = {
            name = 'a',
            state = File.FILE_STATE.not_staged,
          },
        },
        {
          str = '',
          file = {
            name = 'b',
            state = File.FILE_STATE.untracked,
          },
        },
        {
          str = '',
          file = {
            name = 'c',
            state = File.FILE_STATE.not_staged,
          },
        },
        {
          str = '',
          file = {
            name = 'd',
            state = File.FILE_STATE.not_staged,
          },
        },
      }
      assert.equal(0, line.staged_files(lines))
    end)
  end)
end)
