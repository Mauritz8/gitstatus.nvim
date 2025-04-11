local line = require('gitstatus.line')
require('gitstatus.file')

local file = {
  name = '',
  state = FILE_STATE.staged,
  type = FILE_EDIT_TYPE.modified,
}

describe('line.lua', function()
  describe('next_file_index', function()
    it('has next file', function()
      local lines = {
        { str = '', file = nil },
        { str = '', file = file },
        { str = '', file = nil },
        { str = '', file = file },
        { str = '', file = nil },
      }
      local next_file_index = line.next_file_index(lines, 2)
      assert.equal(4, next_file_index)
    end)
    it('on last file', function()
      local lines = {
        { str = '', file = nil },
        { str = '', file = file },
        { str = '', file = nil },
        { str = '', file = file },
        { str = '', file = nil },
      }
      local next_file_index = line.next_file_index(lines, 4)
      assert.equal(4, next_file_index)
    end)
  end)
  describe('prev_file_index', function()
    it('has previous file', function()
      local lines = {
        { str = '', file = nil },
        { str = '', file = file },
        { str = '', file = nil },
        { str = '', file = file },
        { str = '', file = nil },
      }
      local prev_file_index = line.prev_file_index(lines, 4)
      assert.equal(2, prev_file_index)
    end)
    it('on first file', function()
      local lines = {
        { str = '', file = nil },
        { str = '', file = file },
        { str = '', file = nil },
        { str = '', file = file },
        { str = '', file = nil },
      }
      local prev_file_index = line.prev_file_index(lines, 2)
      assert.equal(2, prev_file_index)
    end)
  end)
end)
