local File = require('gitstatus.file')
local line = require('gitstatus.line')

---@type File
local test_file = {
  path = '',
  state = File.STATE.staged,
  type = File.EDIT_TYPE.modified,
}

describe('line.lua', function()
  describe('next_file_index', function()
    it('has next file', function()
      ---@type Line[]
      local lines = {
        { parts = { str = '' }, file = nil },
        { parts = { str = '' }, file = test_file },
        { parts = { str = '' }, file = nil },
        { parts = { str = '' }, file = test_file },
        { parts = { str = '' }, file = nil },
      }
      local next_file_index = line.next_file_index(lines, 2)
      assert.equal(4, next_file_index)
    end)
    it('on last file', function()
      ---@type Line[]
      local lines = {
        { parts = { str = '' }, file = nil },
        { parts = { str = '' }, file = test_file },
        { parts = { str = '' }, file = nil },
        { parts = { str = '' }, file = test_file },
        { parts = { str = '' }, file = nil },
      }
      local next_file_index = line.next_file_index(lines, 4)
      assert.equal(nil, next_file_index)
    end)
  end)
  describe('prev_file_index', function()
    it('has previous file', function()
      ---@type Line[]
      local lines = {
        { parts = { str = '' }, file = nil },
        { parts = { str = '' }, file = test_file },
        { parts = { str = '' }, file = nil },
        { parts = { str = '' }, file = test_file },
        { parts = { str = '' }, file = nil },
      }
      local prev_file_index = line.prev_file_index(lines, 4)
      assert.equal(2, prev_file_index)
    end)
    it('on first file', function()
      ---@type Line[]
      local lines = {
        { parts = { str = '' }, file = nil },
        { parts = { str = '' }, file = test_file },
        { parts = { str = '' }, file = nil },
        { parts = { str = '' }, file = test_file },
        { parts = { str = '' }, file = nil },
      }
      local prev_file_index = line.prev_file_index(lines, 2)
      assert.equal(nil, prev_file_index)
    end)
  end)
  describe('line_index_of_file', function()
    it('file exists', function()
      ---@type File
      local file = {
        path = 'b',
        state = File.STATE.not_staged,
      }
      ---@type Line[]
      local lines = {
        {
          parts = { str = '' },
          file = {
            path = 'a',
            state = File.STATE.not_staged,
          },
        },
        {
          parts = { str = '' },
          file = {
            path = 'b',
            state = File.STATE.not_staged,
          },
        },
        {
          parts = { str = '' },
          file = {
            path = 'c',
            state = File.STATE.not_staged,
          },
        },
      }
      local line_index = line.line_index_of_file(lines, file)
      assert.equal(2, line_index)
    end)
    it('file does not exist', function()
      ---@type File
      local file = {
        path = 'd',
        state = File.STATE.not_staged,
      }
      ---@type Line[]
      local lines = {
        {
          parts = { str = '' },
          file = {
            path = 'a',
            state = File.STATE.not_staged,
          },
        },
        {
          parts = { str = '' },
          file = {
            path = 'b',
            state = File.STATE.not_staged,
          },
        },
        {
          parts = { str = '' },
          file = {
            path = 'c',
            state = File.STATE.not_staged,
          },
        },
      }
      local line_index = line.line_index_of_file(lines, file)
      assert.equal(nil, line_index)
    end)
  end)
  describe('staged_files', function()
    it('multiple staged files', function()
      ---@type Line[]
      local lines = {
        {
          parts = { str = '' },
          file = {
            path = 'a',
            state = File.STATE.staged,
          },
        },
        {
          parts = { str = '' },
          file = {
            path = 'b',
            state = File.STATE.untracked,
          },
        },
        {
          parts = { str = '' },
          file = {
            path = 'c',
            state = File.STATE.not_staged,
          },
        },
        {
          parts = { str = '' },
          file = {
            path = 'd',
            state = File.STATE.staged,
          },
        },
      }
      assert.equal(2, line.staged_files(lines))
    end)
    it('no staged files', function()
      ---@type Line[]
      local lines = {
        {
          parts = { str = '' },
          file = {
            path = 'a',
            state = File.STATE.not_staged,
          },
        },
        {
          parts = { str = '' },
          file = {
            path = 'b',
            state = File.STATE.untracked,
          },
        },
        {
          parts = { str = '' },
          file = {
            path = 'c',
            state = File.STATE.not_staged,
          },
        },
        {
          parts = { str = '' },
          file = {
            path = 'd',
            state = File.STATE.not_staged,
          },
        },
      }
      assert.equal(0, line.staged_files(lines))
    end)
  end)
end)
