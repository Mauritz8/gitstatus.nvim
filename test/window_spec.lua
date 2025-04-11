local window = require('gitstatus.window')

describe('window.lua', function()
  it('width', function()
    local lines = {
      { str = 'test test test' },
      { str = 'test' },
      { str = 'test test' },
    }
    local numberwidth = 1
    local width = window.width(lines, numberwidth)
    assert.equal(14 + 1 + 5, width)
  end)
  it('height', function()
    local lines = {
      { str = 'test test test' },
      { str = 'test' },
      { str = 'test test' },
    }
    local height = window.height(lines)
    assert.equal(3, height)
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
