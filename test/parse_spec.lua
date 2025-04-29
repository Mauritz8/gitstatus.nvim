local Path = require('gitstatus.path')
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
        local input = '?? file.txt\n'
        local paths = parse.git_status(input)
        ---@type Path[]
        local expected = {
          {
            path = 'file.txt',
            orig_path = nil,
            status_code = nil,
          },
        }
        assert.are_same(expected, paths)
      end)
      describe('modified', function()
        it('index', function()
          local input = 'M  file.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file.txt',
              orig_path = nil,
              status_code = {
                x = Path.STATUS.modified,
                y = Path.STATUS.unmodified,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
        it('working tree', function()
          local input = ' M file.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file.txt',
              orig_path = nil,
              status_code = {
                x = Path.STATUS.unmodified,
                y = Path.STATUS.modified,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
      end)
      describe('added', function()
        it('index', function()
          local input = 'A  file.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file.txt',
              orig_path = nil,
              status_code = {
                x = Path.STATUS.added,
                y = Path.STATUS.unmodified,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
        it('working tree', function()
          local input = ' A file.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file.txt',
              orig_path = nil,
              status_code = {
                x = Path.STATUS.unmodified,
                y = Path.STATUS.added,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
      end)
      describe('deleted', function()
        it('index', function()
          local input = 'D  file.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file.txt',
              orig_path = nil,
              status_code = {
                x = Path.STATUS.deleted,
                y = Path.STATUS.unmodified,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
        it('working tree', function()
          local input = ' D file.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file.txt',
              orig_path = nil,
              status_code = {
                x = Path.STATUS.unmodified,
                y = Path.STATUS.deleted,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
      end)
      describe('renamed', function()
        it('index', function()
          local input = 'R  file1.txt -> file2.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file2.txt',
              orig_path = 'file1.txt',
              status_code = {
                x = Path.STATUS.renamed,
                y = Path.STATUS.unmodified,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
        it('working tree', function()
          local input = ' R file1.txt -> file2.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file2.txt',
              orig_path = 'file1.txt',
              status_code = {
                x = Path.STATUS.unmodified,
                y = Path.STATUS.renamed,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
        it('subdirectory', function()
          local input = 'R  dir/subdir/abc.txt -> dir/a.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'dir/a.txt',
              orig_path = 'dir/subdir/abc.txt',
              status_code = {
                x = Path.STATUS.renamed,
                y = Path.STATUS.unmodified,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
        it('path with -', function()
          local input = 'R  def-abc.txt -> abc-def.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'abc-def.txt',
              orig_path = 'def-abc.txt',
              status_code = {
                x = Path.STATUS.renamed,
                y = Path.STATUS.unmodified,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
        it('path with >', function()
          local input = 'R  def>abc.txt -> abc>def.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'abc>def.txt',
              orig_path = 'def>abc.txt',
              status_code = {
                x = Path.STATUS.renamed,
                y = Path.STATUS.unmodified,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
      end)
      describe('file type changed', function()
        it('index', function()
          local input = 'T  file.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file.txt',
              orig_path = nil,
              status_code = {
                x = Path.STATUS.file_type_changed,
                y = Path.STATUS.unmodified,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
        it('working tree', function()
          local input = ' T file.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file.txt',
              orig_path = nil,
              status_code = {
                x = Path.STATUS.unmodified,
                y = Path.STATUS.file_type_changed,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
      end)
      describe('copied', function()
        it('index', function()
          local input = 'C  file.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file.txt',
              orig_path = nil,
              status_code = {
                x = Path.STATUS.copied,
                y = Path.STATUS.unmodified,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
        it('working tree', function()
          local input = ' C file.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file.txt',
              orig_path = nil,
              status_code = {
                x = Path.STATUS.unmodified,
                y = Path.STATUS.copied,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
      end)
      describe('updated but unmerged', function()
        it('index', function()
          local input = 'U  file.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file.txt',
              orig_path = nil,
              status_code = {
                x = Path.STATUS.updated_but_unmerged,
                y = Path.STATUS.unmodified,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
        it('working tree', function()
          local input = ' U file.txt\n'
          local paths = parse.git_status(input)
          ---@type Path[]
          local expected = {
            {
              path = 'file.txt',
              orig_path = nil,
              status_code = {
                x = Path.STATUS.unmodified,
                y = Path.STATUS.updated_but_unmerged,
              },
            },
          }
          assert.are_same(expected, paths)
        end)
      end)
      it('path that contains spaces', function()
        local input = '?? "a path with spaces.txt"\n'
        local paths = parse.git_status(input)
        ---@type Path[]
        local expected = {
          {
            path = 'a path with spaces.txt',
            orig_path = nil,
            status_code = nil,
          },
        }
        assert.are_same(expected, paths)
      end)
    end)
    it('paths changed in index and working tree', function()
      local input = 'MM a.txt\nAD b.txt\nRT c.txt -> d.txt\n'
      local paths = parse.git_status(input)
      ---@type Path[]
      local expected = {
        {
          path = 'a.txt',
          orig_path = nil,
          status_code = {
            x = Path.STATUS.modified,
            y = Path.STATUS.modified,
          },
        },
        {
          path = 'b.txt',
          orig_path = nil,
          status_code = {
            x = Path.STATUS.added,
            y = Path.STATUS.deleted,
          },
        },
        {
          path = 'd.txt',
          orig_path = 'c.txt',
          status_code = {
            x = Path.STATUS.renamed,
            y = Path.STATUS.file_type_changed,
          },
        },
      }
      assert.are_same(expected, paths)
    end)
  end)
end)
