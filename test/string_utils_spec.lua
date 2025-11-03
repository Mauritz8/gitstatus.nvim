local StringUtils = require('gitstatus.string_utils')

describe('string_utils.lua', function()
  describe('strip_trailing_newline', function()
    it('string with trailing newline', function()
      local str = 'hello\n'
      assert.equal('hello', StringUtils.strip_trailing_newline(str))
    end)
    it('string without trailing newline', function()
      local str = 'hello'
      assert.equal('hello', StringUtils.strip_trailing_newline(str))
    end)
  end)
end)
