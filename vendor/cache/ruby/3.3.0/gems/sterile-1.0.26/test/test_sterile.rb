require "test_helper"

class TestSterile < Minitest::Test

  def test_decode_entities
    assert_equal "“Hey” you", Sterile.decode_entities("&ldquo;Hey&rdquo; you")

    # try all variants
    assert_equal "°", Sterile.decode_entities("&deg;")
    assert_equal "°", Sterile.decode_entities("&#176;")
    assert_equal "°", Sterile.decode_entities("&#000176;")
    assert_equal "°", Sterile.decode_entities("&#x000b0;")
    assert_equal "°", Sterile.decode_entities("&#x000B0;")
  end

  def test_encode_entities
    assert_equal "&ldquo;Hey&rdquo; you", Sterile.encode_entities("“Hey” you")
  end

  def test_gsub_tags
    assert_equal "A<i>B</i>C", Sterile.gsub_tags("a<i>b</i>c", &:upcase)
  end

  def test_plain_format
    s = "&#169; &copy; &#8482; &trade;"
    assert_equal "(c) (c) (tm) (tm)", Sterile.plain_format(s)
  end

  def test_plain_format_tags
    s = '<i x="&copy;">&copy;</i>'
    assert_equal '<i x="&copy;">(c)</i>', Sterile.plain_format_tags(s)
  end

  def test_scan_tags
    text = []
    Sterile.scan_tags("a<i>b</i>c") { |i| text << i }
    assert_equal %w[a b c], text
  end

  def test_sluggerize
    assert_equal "hello-world", Sterile.sluggerize("Hello world!")
  end

  def test_smart_format
    s = "\"He said, 'Away, Drake!'\""
    assert_equal "“He said, ‘Away, Drake!’”", Sterile.smart_format(s)
  end

  def test_smart_format_times
    assert_equal "1×1", Sterile.smart_format("1x1")
    assert_equal "0×1", Sterile.smart_format("0x1")
    assert_equal "1×0", Sterile.smart_format("1x0")
    assert_equal "12×21", Sterile.smart_format("12x21")
    assert_equal "01x1", Sterile.smart_format("01x1")
    assert_equal "1x01", Sterile.smart_format("1x01")
  end

  def test_smart_format_tags
    # ?
  end

  def test_sterilize
    assert_equal "nasty", Sterile.sterilize("<b>nåsty</b>")
  end

  def test_strip_tags
    s = 'Visit <a href="http://example.com">site!</a>'
    assert_equal "Visit site!", Sterile.strip_tags(s)
  end

  def test_titlecase
    s = "Q&A: 'That's what happens'"
    assert_equal "Q&A: 'That's What Happens'", Sterile.titlecase(s)
  end

  def test_transliterate
    assert_equal "yucky", Sterile.transliterate("ýůçký")
  end

  def test_trim_whitespace
    assert_equal "Hello world!", Sterile.trim_whitespace(" Hello  world! ")
  end

  def test_quote_slash_quote
    assert_equal "“one”/“two”", Sterile.smart_format('"one"/"two"')
    assert_equal "‘one’/‘two’", Sterile.smart_format("'one'/'two'")
  end

  def test_number_single_quote
    assert_equal "War in ’24", Sterile.smart_format("War in '24")
  end

  def test_number_single_quote_in_double_quotes
    assert_equal "“War in ’24”", Sterile.smart_format("\"War in '24\"")
  end

end

