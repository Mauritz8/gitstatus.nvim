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
  describe('str_starts_with', function()
    it('starts with #', function()
      local str = '# hello'
      assert.is_true(StringUtils.str_starts_with(str, '#'))
    end)
    it('does not start with #', function()
      local str = 'hello'
      assert.is_false(StringUtils.str_starts_with(str, '#'))
    end)
  end)
  describe('filter', function()
    it('basic', function()
      local strings = { 'a', 'b', 'b', 'a', 'b' }
      local is_a = function(str) return str == 'a' end
      assert.are_same({ 'a', 'a' }, StringUtils.filter(strings, is_a))
    end)
  end)
end)
