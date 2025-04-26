local Path = require('gitstatus.path')
local file = require('gitstatus.file')

describe('file.lua', function()
  describe('paths_to_files', function()
    it('changed in index', function()
      ---@type Path[]
      local paths = {
        {
          path = 'file.txt',
          orig_path = nil,
          x = Path.STATUS.modified,
          y = Path.STATUS.unmodified,
          untracked = false,
        },
      }
      local files = file.paths_to_files(paths)
      ---@type File[]
      local expected = {
        {
          path = 'file.txt',
          orig_path = nil,
          state = file.STATE.staged,
          type = file.EDIT_TYPE.modified,
        },
      }
      assert.are_same(expected, files)
    end)
    it('changed in working tree', function()
      ---@type Path[]
      local paths = {
        {
          path = 'file.txt',
          orig_path = nil,
          x = Path.STATUS.unmodified,
          y = Path.STATUS.modified,
          untracked = false,
        },
      }
      local files = file.paths_to_files(paths)
      ---@type File[]
      local expected = {
        {
          path = 'file.txt',
          orig_path = nil,
          state = file.STATE.not_staged,
          type = file.EDIT_TYPE.modified,
        },
      }
      assert.are_same(expected, files)
    end)
    describe('changed in index and working tree', function()
      it('basic', function()
        ---@type Path[]
        local paths = {
          {
            path = 'file.txt',
            orig_path = nil,
            x = Path.STATUS.file_type_changed,
            y = Path.STATUS.modified,
            untracked = false,
          },
        }
        local files = file.paths_to_files(paths)
        ---@type File[]
        local expected = {
          {
            path = 'file.txt',
            orig_path = nil,
            state = file.STATE.staged,
            type = file.EDIT_TYPE.file_type_changed,
          },
          {
            path = 'file.txt',
            orig_path = nil,
            state = file.STATE.not_staged,
            type = file.EDIT_TYPE.modified,
          },
        }
        assert.are_same(expected, files)
      end)
      it('renamed path', function()
        ---@type Path[]
        local paths = {
          {
            path = 'file2.txt',
            orig_path = 'file1.txt',
            x = Path.STATUS.renamed,
            y = Path.STATUS.modified,
            untracked = false,
          },
        }
        local files = file.paths_to_files(paths)
        ---@type File[]
        local expected = {
          {
            path = 'file2.txt',
            orig_path = 'file1.txt',
            state = file.STATE.staged,
            type = file.EDIT_TYPE.renamed,
          },
          {
            path = 'file2.txt',
            orig_path = nil,
            state = file.STATE.not_staged,
            type = file.EDIT_TYPE.modified,
          },
        }
        assert.are_same(expected, files)
      end)
    end)
  end)
end)
