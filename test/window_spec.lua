local window = require('gitstatus.window')

describe('window.lua', function()
  describe('width', function()
    it('normal', function()
      local lines = {
        { str = 'test test test' },
        { str = 'test' },
        { str = 'test test' },
      }
      local width = window.width(lines, 1, 100)
      assert.equal(14 + 1 + 5, width)
    end)
    it('do not exceed parent window width', function()
      local lines = {
        { str = 'test test test' },
        { str = 'test' },
        { str = 'test test' },
      }
      local width = window.width(lines, 1, 10)
      assert.equal(10, width)
    end)
  end)
  describe('height', function()
    it('normal', function()
      local lines = {
        { str = 'test test test' },
        { str = 'test' },
        { str = 'test test' },
      }
      local height = window.height(lines, 10)
      assert.equal(3, height)
    end)
    it('do not exceed parent window height', function()
      local lines = {
        { str = 'test test test' },
        { str = 'test' },
        { str = 'test test' },
      }
      local height = window.height(lines, 2)
      assert.equal(2, height)
    end)
  end)
  it('row', function()
    local row = window.row(10, 5)
    assert.equal(2.5, row)
  end)
  it('column', function()
    local column = window.column(10, 5)
    assert.equal(2.5, column)
  end)
end)
