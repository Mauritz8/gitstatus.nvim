local file = require('gitstatus.file')
local parse = require('gitstatus.parse')

describe('parse.lua', function()
  describe('git_branch', function()
    it('only main exists', function()
      local input = '* main'
      local branch = parse.git_branch(input)
      assert.equal('main', branch)
    end)
    it('two branches on main', function()
      local input = '* main\ndev'
      local branch = parse.git_branch(input)
      assert.equal('main', branch)
    end)
    it('two branches not on main', function()
      local input = 'main\n* dev'
      local branch = parse.git_branch(input)
      assert.equal('dev', branch)
    end)
  end)
  describe('git_status', function()
    it('no changes', function()
      local input = ''
      local files = parse.git_status(input)
      assert.are_same({}, files)
    end)
    describe('single file', function()
      it('untracked', function()
        local input = '?? file.txt'
        local files = parse.git_status(input)
        local expected = {
          {
            name = 'file.txt',
            state = file.FILE_STATE.untracked,
            type = file.FILE_EDIT_TYPE.none,
          },
        }
        assert.are_same(expected, files)
      end)
      it('not staged modified', function()
        local input = ' M file.txt'
        local files = parse.git_status(input)
        local expected = {
          {
            name = 'file.txt',
            state = file.FILE_STATE.not_staged,
            type = file.FILE_EDIT_TYPE.modified,
          },
        }
        assert.are_same(expected, files)
      end)
      it('not staged deleted', function()
        local input = ' D file.txt'
        local files = parse.git_status(input)
        local expected = {
          {
            name = 'file.txt',
            state = file.FILE_STATE.not_staged,
            type = file.FILE_EDIT_TYPE.deleted,
          },
        }
        assert.are_same(expected, files)
      end)
      it('staged modified', function()
        local input = 'M  file.txt'
        local files = parse.git_status(input)
        local expected = {
          {
            name = 'file.txt',
            state = file.FILE_STATE.staged,
            type = file.FILE_EDIT_TYPE.modified,
          },
        }
        assert.are_same(expected, files)
      end)
      it('staged deleted', function()
        local input = 'D  file.txt'
        local files = parse.git_status(input)
        local expected = {
          {
            name = 'file.txt',
            state = file.FILE_STATE.staged,
            type = file.FILE_EDIT_TYPE.deleted,
          },
        }
        assert.are_same(expected, files)
      end)
      it('staged new file', function()
        local input = 'A  file.txt'
        local files = parse.git_status(input)
        local expected = {
          {
            name = 'file.txt',
            state = file.FILE_STATE.staged,
            type = file.FILE_EDIT_TYPE.new,
          },
        }
        assert.are_same(expected, files)
      end)
      it('staged renamed', function()
        local input = 'R  file.txt -> new.txt'
        local files = parse.git_status(input)
        local expected = {
          {
            name = 'file.txt -> new.txt',
            state = file.FILE_STATE.staged,
            type = file.FILE_EDIT_TYPE.renamed,
          },
        }
        assert.are_same(expected, files)
      end)
    end)
  end)
  it('git_renamed_file', function()
    local str = 'dir/subdir/abc.txt -> dir/a.txt'
    local old_name, new_name, err = parse.git_renamed_file(str)
    assert.equal('dir/subdir/abc.txt', old_name)
    assert.equal('dir/a.txt', new_name)
    assert.is_nil(err)
  end)
end)
