local file = require('gitstatus.file')
local parse = require('gitstatus.parse')

describe('parse.lua', function()
  describe('git_branch', function()
    it('with newline', function()
      local input = 'main\n'
      local branch = parse.git_branch(input)
      assert.equal('main', branch)
    end)
    it('without newline', function()
      local input = 'main'
      local branch = parse.git_branch(input)
      assert.equal('main', branch)
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
      describe('not staged', function()
        it('added', function()
          local input = ' A file.txt'
          local files = parse.git_status(input)
          local expected = {
            {
              name = 'file.txt',
              state = file.FILE_STATE.not_staged,
              type = file.FILE_EDIT_TYPE.new,
            },
          }
          assert.are_same(expected, files)
        end)
        it('modified', function()
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
        it('deleted', function()
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
        it('renamed', function()
          local input = ' R file1.txt -> file2.txt'
          local files = parse.git_status(input)
          local expected = {
            {
              name = 'file1.txt -> file2.txt',
              state = file.FILE_STATE.not_staged,
              type = file.FILE_EDIT_TYPE.renamed,
            },
          }
          assert.are_same(expected, files)
        end)
        it('file type changed', function()
          local input = ' T file.txt'
          local files = parse.git_status(input)
          local expected = {
            {
              name = 'file.txt',
              state = file.FILE_STATE.not_staged,
              type = file.FILE_EDIT_TYPE.file_type_changed,
            },
          }
          assert.are_same(expected, files)
        end)
        it('copied', function()
          local input = ' C file.txt'
          local files = parse.git_status(input)
          local expected = {
            {
              name = 'file.txt',
              state = file.FILE_STATE.not_staged,
              type = file.FILE_EDIT_TYPE.copied,
            },
          }
          assert.are_same(expected, files)
        end)
      end)
      describe('staged', function()
        it('added', function()
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
        it('modified', function()
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
        it('deleted', function()
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
        it('renamed', function()
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
        it('file type changed', function()
          local input = 'T  file.txt'
          local files = parse.git_status(input)
          local expected = {
            {
              name = 'file.txt',
              state = file.FILE_STATE.staged,
              type = file.FILE_EDIT_TYPE.file_type_changed,
            },
          }
          assert.are_same(expected, files)
        end)
        it('copied', function()
          local input = 'C  file.txt'
          local files = parse.git_status(input)
          local expected = {
            {
              name = 'file.txt',
              state = file.FILE_STATE.staged,
              type = file.FILE_EDIT_TYPE.copied,
            },
          }
          assert.are_same(expected, files)
        end)
      end)
      it('filename that contains spaces', function()
        local input = '?? "a file with spaces.txt"'
        local files = parse.git_status(input)
        local expected = {
          {
            name = 'a file with spaces.txt',
            state = file.FILE_STATE.untracked,
            type = file.FILE_EDIT_TYPE.none,
          },
        }
        assert.are_same(expected, files)
      end)
    end)
    it('files changed in index and working tree', function()
      local input = 'MM a.txt\nAD b.txt\nRT c.txt -> d.txt'
      local files = parse.git_status(input)
      local expected = {
        {
          name = 'a.txt',
          state = file.FILE_STATE.staged,
          type = file.FILE_EDIT_TYPE.modified,
        },
        {
          name = 'a.txt',
          state = file.FILE_STATE.not_staged,
          type = file.FILE_EDIT_TYPE.modified,
        },
        {
          name = 'b.txt',
          state = file.FILE_STATE.staged,
          type = file.FILE_EDIT_TYPE.new,
        },
        {
          name = 'b.txt',
          state = file.FILE_STATE.not_staged,
          type = file.FILE_EDIT_TYPE.deleted,
        },
        {
          name = 'c.txt -> d.txt',
          state = file.FILE_STATE.staged,
          type = file.FILE_EDIT_TYPE.renamed,
        },
        {
          name = 'c.txt -> d.txt',
          state = file.FILE_STATE.not_staged,
          type = file.FILE_EDIT_TYPE.file_type_changed,
        },
      }
      assert.are_same(expected, files)
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
