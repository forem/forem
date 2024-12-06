require 'test/unit'
require 'buftok'

class TestBuftok < Test::Unit::TestCase
  def test_buftok
    tokenizer = BufferedTokenizer.new
    assert_equal %w[foo], tokenizer.extract("foo\nbar".freeze)
    assert_equal %w[barbaz qux], tokenizer.extract("baz\nqux\nquu".freeze)
    assert_equal 'quu', tokenizer.flush
    assert_equal '', tokenizer.flush
  end

  def test_delimiter
    tokenizer = BufferedTokenizer.new('<>')
    assert_equal ['', "foo\n"], tokenizer.extract("<>foo\n<>".freeze)
    assert_equal %w[bar], tokenizer.extract('bar<>baz'.freeze)
    assert_equal 'baz', tokenizer.flush
  end

  def test_split_delimiter
    tokenizer = BufferedTokenizer.new('<>'.freeze)
    assert_equal [], tokenizer.extract('foo<'.freeze)
    assert_equal %w[foo], tokenizer.extract('>bar<'.freeze)
    assert_equal %w[bar<baz qux], tokenizer.extract('baz<>qux<>'.freeze)
    assert_equal '', tokenizer.flush
  end
end
