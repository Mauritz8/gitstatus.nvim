local parser = require('gitstatus.parser')

describe('parser.lua', function()
  describe('parse git branch', function()
    it('only main exists', function()
      local input = '* main'
      local branch = parser.branch(input)
      assert.equal('main', branch)
    end)
    it('two branches on main', function()
      local input = '* main\ndev'
      local branch = parser.branch(input)
      assert.equal('main', branch)
    end)
    it('two branches not on main', function()
      local input = 'main\n* dev'
      local branch = parser.branch(input)
      assert.equal('dev', branch)
    end)
  end)
  describe('parse git status', function()
    it('no changes', function()
      local input = ''
      local files = parser.retrieve_files(input)
      assert.are_same({}, files)
    end)
    describe('single file', function()
      it('untracked', function()
        local input = '?? file.txt'
        local files = parser.retrieve_files(input)
        local expected = {
          {
            name = 'file.txt',
            state = FILE_STATE.untracked,
            type = FILE_EDIT_TYPE.none,
          }
        }
        assert.are_same(expected, files)
      end)
      it('not staged modified', function()
        local input = ' M file.txt'
        local files = parser.retrieve_files(input)
        local expected = {
          {
            name = 'file.txt',
            state = FILE_STATE.not_staged,
            type = FILE_EDIT_TYPE.modified,
          }
        }
        assert.are_same(expected, files)
      end)
      it('not staged deleted', function()
        local input = ' D file.txt'
        local files = parser.retrieve_files(input)
        local expected = {
          {
            name = 'file.txt',
            state = FILE_STATE.not_staged,
            type = FILE_EDIT_TYPE.deleted,
          }
        }
        assert.are_same(expected, files)
      end)
      it('staged modified', function()
        local input = 'M  file.txt'
        local files = parser.retrieve_files(input)
        local expected = {
          {
            name = 'file.txt',
            state = FILE_STATE.staged,
            type = FILE_EDIT_TYPE.modified,
          }
        }
        assert.are_same(expected, files)
      end)
      it('staged deleted', function()
        local input = 'D  file.txt'
        local files = parser.retrieve_files(input)
        local expected = {
          {
            name = 'file.txt',
            state = FILE_STATE.staged,
            type = FILE_EDIT_TYPE.deleted,
          }
        }
        assert.are_same(expected, files)
      end)
      it('staged new file', function()
        local input = 'A  file.txt'
        local files = parser.retrieve_files(input)
        local expected = {
          {
            name = 'file.txt',
            state = FILE_STATE.staged,
            type = FILE_EDIT_TYPE.new,
          }
        }
        assert.are_same(expected, files)
      end)
      it('staged renamed', function()
        local input = 'R  file.txt -> new.txt'
        local files = parser.retrieve_files(input)
        local expected = {
          {
            name = 'file.txt',
            state = FILE_STATE.staged,
            type = FILE_EDIT_TYPE.deleted,
          },
          {
            name = 'new.txt',
            state = FILE_STATE.staged,
            type = FILE_EDIT_TYPE.new,
          },
        }
        assert.are_same(expected, files)
      end)
    end)
  end)
end)
