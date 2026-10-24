require "rails_helper"

RSpec.describe ForemNative do
  let(:legacy_split_word_count) do
    ->(content) { content.to_s.split(/\W+/).count }
  end

  let(:legacy_calculate_reading_time) do
    ->(content) { (legacy_split_word_count.call(content) / 275.0).ceil }
  end

  describe ".available? and Builder.normalized_platform" do
    it "loads the compiled Rust native extension directly" do
      expect(described_class.available?).to be(true)
      expect(described_class.native_loaded?).to be(true)
    end

    it "normalizes OS version suffixes on RUBY_PLATFORM for precompiled binary lookup" do
      expect(ForemNative::Builder.normalized_platform("arm64-darwin23")).to eq("arm64-darwin")
      expect(ForemNative::Builder.normalized_platform("x86_64-darwin22")).to eq("x86_64-darwin")
      expect(ForemNative::Builder.normalized_platform("x86_64-linux-gnu")).to eq("x86_64-linux")
      expect(ForemNative::Builder.normalized_platform("x86_64-linux")).to eq("x86_64-linux")
      expect(ForemNative::Builder.precompiled_binary_exists?).to be(true)
    end
  end

  describe ".split_word_count and .calculate_reading_time" do
    let(:edge_cases) do
      [
        nil,
        "",
        "   ",
        "\n\t\r",
        "... --- !!! ???",
        "🚀 🌟 🎉",
        "hello",
        "hello world",
        "  hello world  ",
        "...hello...world...",
        "\n\thello\n",
        "123_456",
        "café résumé",
        "🚀 hello 🌟",
        "日本語 test 123",
        "```ruby\ndef foo_bar(x = 1)\n  x + 2\nend\n```",
        Array.new(274, "word").join(" "),
        Array.new(275, "word").join(" "),
        " #{Array.new(275, 'word').join(' ')}",
        Array.new(276, "word").join(" "),
        Array.new(550, "word").join(" "),
        Array.new(551, "word").join(" "),
      ]
    end

    it "matches the legacy Ruby reference calculation across all edge cases and boundary conditions" do
      edge_cases.each do |input|
        expected_words = legacy_split_word_count.call(input)
        expected_minutes = legacy_calculate_reading_time.call(input)

        expect(described_class.split_word_count(input)).to eq(expected_words),
                                                           "word count mismatch for #{input.inspect}"
        expect(described_class.calculate_reading_time(input)).to eq(expected_minutes),
                                                                 "reading time mismatch for #{input.inspect}"
      end
    end

    it "passes differential equivalence across 1,000 generated Markdown and Unicode inputs" do
      tokens = [
        "word", "Rust", "Ruby_3_3", "0", "42", " ", "  ", "\n", "\r\n", "\t",
        ".", ",", "!", "-", "_", "`", "```", "|", "\\|", "é", "ü", "🚀", "中",
        "[link](https://dev.to)", "{% raw %}", "## Heading"
      ]
      rng = Random.new(20_261_023)

      1_000.times do |iteration|
        piece_count = rng.rand(0..120)
        sample = Array.new(piece_count) { tokens.sample(random: rng) }.join

        expected_words = legacy_split_word_count.call(sample)
        actual_words = described_class.split_word_count(sample)
        expect(actual_words).to eq(expected_words),
                                "Differential word_count mismatch at iteration #{iteration} for #{sample.inspect}"

        expected_time = legacy_calculate_reading_time.call(sample)
        actual_time = described_class.calculate_reading_time(sample)
        expect(actual_time).to eq(expected_time),
                               "Differential reading_time mismatch at iteration #{iteration} for #{sample.inspect}"
      end
    end
  end

  describe ".color_brightness" do
    let(:legacy_brightness) do
      lambda do |hex, amount, only_values|
        rgb = hex.match(/^#?(?<r>..)(?<g>..)(?<b>..)$/).named_captures.to_h { |key, color| [key.to_sym, color.hex] }
        rgb = rgb.transform_values { |color| (color * amount).round }
        only_values ? format("%<r>d, %<g>d, %<b>d", rgb) : format("#%<r>02x%<g>02x%<b>02x", rgb)
      rescue StandardError
        hex
      end
    end

    let(:edge_hexes) do
      [
        nil, "", "#", "#fff", "#12345", "#1234567", "##12345", "#ccddee", "ccddee", "#CCDDEE", "#000000",
        "#ffffff", "#-1-1-1", "#0x0x0x", "# 1 2 3", "#1_2_3_", "#12345g", "#ccddee\n", "\n#ccddee",
        "foo\n#ccddee", "#ccddee\r\n", "#éééééé", "#🚀🚀🚀", "#日本語", "#ccddee".encode("UTF-16LE"),
        "#ccddee".b, :"#ccddee"
      ]
    end

    let(:edge_amounts) do
      [1, 0, -1, 2, 0.0, -0.0, 0.5, 0.625, 0.8, 0.88, 1.0, 1.35, -0.4, -0.6, 1e300, -1e300, 2**40,
       Float::INFINITY, -Float::INFINITY, Float::NAN, Rational(1, 2), nil, "1"] +
        Color::CompareHex::ACCENT_MODIFIERS
    end

    it "matches the legacy Ruby reference across edge-case hexes and amounts" do
      edge_hexes.product(edge_amounts, [false, true]).each do |hex, amount, only_values|
        expected = legacy_brightness.call(hex, amount, only_values)
        native = described_class.color_brightness(hex, amount, only_values: only_values)
        actual = Color::CompareHex.new([hex]).brightness(amount, only_values: only_values)
        message = "mismatch for #{hex.inspect} * #{amount.inspect} (only_values: #{only_values})"
        if expected.is_a?(String)
          expect(native).to eq(expected), message unless native.nil?
          expect(actual).to eq(expected), message
          expect(actual.encoding).to eq(expected.encoding), message
        else
          expect(native).to be_nil, message
          expect(actual).to equal(expected), message
        end
      end
    end

    it "returns nil from the native function for inputs outside the strict #rrggbb domain" do
      expect(ForemNative::Native.color_brightness("#ccddee", 0.5, false)).to eq("#666f77")
      expect(ForemNative::Native.color_brightness("#ccddee\n", 0.5, false)).to be_nil
      expect(ForemNative::Native.color_brightness("#010101", -0.6, false)).to be_nil
      expect(ForemNative::Native.color_brightness("#ffffff", Float::NAN, true)).to be_nil
    end

    it "passes differential equivalence across 1,000 generated hex colors and amounts" do
      srand(424_242)
      rng = Random.new(424_242)
      hex_chars = [*"0".."9", *"a".."f", *"A".."F"]
      noise_chars = hex_chars + ["#", "-", "+", " ", "_", "x", "g", "\n", "é", "🚀"]
      modifiers = Color::CompareHex::ACCENT_MODIFIERS + [0.625, 0.88, 1.35, 0.8, 1, 0, 2]

      1_000.times do |iteration|
        prefix = rng.rand < 0.8 ? "#" : ""
        hex = if rng.rand < 0.85
                prefix + Array.new(6) { hex_chars.sample(random: rng) }.join
              else
                prefix + Array.new(rng.rand(0..8)) { noise_chars.sample(random: rng) }.join
              end
        amount = case rng.rand(4)
                 when 0 then modifiers.sample(random: rng)
                 when 1 then Color::CompareHex::ACCENT_MODIFIERS.sample(random: rng)**rng.rand(-3..3)
                 when 2 then (rng.rand * 4.0) - 0.5
                 else rng.rand(-2..5)
                 end
        only_values = rng.rand < 0.5

        expected = legacy_brightness.call(hex, amount, only_values)
        native = described_class.color_brightness(hex, amount, only_values: only_values)
        message = "iteration #{iteration}: #{hex.inspect} * #{amount.inspect} (only_values: #{only_values})"

        expect(native).to eq(expected), message unless native.nil?
        expect(Color::CompareHex.new([hex]).brightness(amount, only_values: only_values)).to eq(expected), message
      end
    end
  end

  describe ".convert_deeply_nested_links_to_html" do
    let(:legacy_convert_deeply_nested_links_to_html) do
      lambda do |content|
        content.gsub(/^(?: {16,}|\t{4,})[-*+ \d.]* .*$/) do |line|
          line.gsub(/\[([^\]]*)\]\(([^)]*)\)/) { "<a href=\"#{Regexp.last_match(2)}\">#{Regexp.last_match(1)}</a>" }
        end
      end
    end

    let(:parser) { MarkdownProcessor::Parser.new("") }
    let(:deep) { " " * 16 }

    let(:edge_cases) do
      [
        "", "\n", "\r\n", "[a](b)", "- [a](b)", "#{' ' * 15}- [a](b)", "#{deep}- [a](b)", "#{deep}x [a](b)",
        "#{deep}-[a](b)", "#{deep} [a](b)", "#{deep}1.2 [a](b)", "#{deep}٣ [a](b)", "\t\t\t- [a](b)",
        "\t\t\t\t- [a](b)", "\t\t\t\t\t* [a](b)", "\t\t\t\tx [a](b)", "\t\t\t\t \t[a](b)", "x#{deep}- [a](b)",
        "#{deep}- [a [b](c)", "#{deep}- [a] [b](c)", "#{deep}- [](  )", "#{deep}- [a](b(c))", "#{deep}- [a](b",
        "#{deep}- [a]](b)", "#{deep}- [[a]](b)", "#{deep}- [a\n](b)", "#{deep}- [a](b)\r\n#{deep}+ [c](d)\r\n",
        "#{deep}- [日本](🚀) é\n[x](y)\n#{deep}- [x](y)", "#{deep}- [a](b)\n\n\n", "\n\n#{deep}- [a](b)",
        "#{deep}- #{'[' * 50}](b)#{')' * 5}"
      ]
    end

    it "matches the legacy Ruby reference across edge cases" do
      edge_cases.each do |input|
        expected = legacy_convert_deeply_nested_links_to_html.call(input)
        expect(described_class.convert_deeply_nested_links_to_html(input)).to eq(expected), input.inspect
        expect(parser.convert_deeply_nested_links_to_html(input)).to eq(expected), input.inspect
      end
    end

    it "declines non-UTF-8, String subclasses, and invalid byte sequences so the parser keeps Ruby semantics" do
      input = "#{deep}- [a](b)"
      expected = "#{deep}- <a href=\"b\">a</a>"

      [input.b, input.dup.force_encoding(Encoding::US_ASCII), ActiveSupport::SafeBuffer.new(input)].each do |other|
        expect(described_class.convert_deeply_nested_links_to_html(other)).to be_nil
        result = parser.convert_deeply_nested_links_to_html(other)
        expect(result).to eq(expected)
        expect(result.encoding).to eq(other.encoding)
      end

      expect(ForemNative::Native.convert_deeply_nested_links_to_html("#{input}\xFF")).to be_nil
      expect { parser.convert_deeply_nested_links_to_html("#{input}\xFF") }
        .to raise_error(ArgumentError, /invalid byte sequence/)
    end

    it "returns a new mutable UTF-8 String whether or not anything was converted" do
      ["#{deep}- [a](b)".freeze, "- [a](b)\n    - [c](d)".freeze].each do |input|
        result = described_class.convert_deeply_nested_links_to_html(input)

        expect(result).to eq(legacy_convert_deeply_nested_links_to_html.call(input))
        expect(result).not_to equal(input)
        expect(result).not_to be_frozen
        expect(result.encoding).to eq(Encoding::UTF_8)
        expect { result << "!" }.not_to(change { input })
      end
    end

    it "passes differential equivalence across 1,000 generated nested-list Markdown inputs" do
      rng = Random.new(424_242)
      indents = ["", " ", "  ", " " * 4, " " * 15, " " * 16, " " * 17, " " * 20, "\t" * 3, "\t" * 4, "\t" * 5,
                 "\t\t\t\t ", " \t\t\t\t"]
      markers = ["", "-", "*", "+", "1.", "10.", "-.", " ", "  ", "x", "٣", "#"]
      tokens = ["[", "]", "(", ")", "[a](b)", "[DEV](https://dev.to)", "[a [b](c)", "](", " ", "  ", "\t", "\r",
                "word", "é", "🚀", "日本", "`", "\\|", "<", "\"", "-", "1"]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..6)) do
          indents.sample(random: rng) + markers.sample(random: rng) +
            (rng.rand < 0.8 ? " " : "") +
            Array.new(rng.rand(0..12)) { tokens.sample(random: rng) }.join
        end.join(rng.rand < 0.2 ? "\r\n" : "\n")
        sample << "\n" if rng.rand < 0.3

        expected = legacy_convert_deeply_nested_links_to_html.call(sample)
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(described_class.convert_deeply_nested_links_to_html(sample)).to eq(expected), message
        expect(parser.convert_deeply_nested_links_to_html(sample)).to eq(expected), message
      end
    end
  end

  describe ".escape_liquid_tags_in_codeblock" do
    let(:legacy_escape_liquid_tags_in_codeblock) do
      lambda do |content|
        content.gsub(/([[:space:]]*(`{3,}|~{3,}))[\s\S]*?\2|`{2}.+?`{2}|`{1}.+?`{1}/m) do |codeblock|
          codeblock.gsub!("{% endraw %}", "{----% endraw %----}")
          codeblock.gsub!("{% raw %}", "{----% raw %----}")
          if codeblock.match?(/[[:space:]]*`{3,}/)
            "\n{% raw %}\n#{codeblock}\n{% endraw %}\n"
          else
            "{% raw %}#{codeblock}{% endraw %}"
          end
        end
      end
    end

    let(:parser) { MarkdownProcessor::Parser.new("") }

    let(:edge_cases) do
      [
        "", "\n", "plain text", "a ` b", "`", "``", "```", "````", "`````", "``````", "`a`", "``a`", "``a``",
        "`a```b`", "````a```", "~~", "~~~", "~~~a", "~~~a~~~", "~~~~a~~~", "~~~\nx\n~~~", "  ```a", " \t```a```",
        "a\n```js\n{{ x }}\n```\nb", "```\r\ncode\r\n```\r\n", " 　 ```x```", "​```x```",
        "᠎```x```", "﻿`x`", "`é` and `日本` 🚀", "`\n`", "{% raw %}`{% raw %}x{% endraw %}`",
        "```\n{% raw %}some text{% endraw %}\n```", "``{% raw %}some text{% endraw %}``", "`{% endraw %}`",
        "`{% raw {% raw %}%}`", "~~~\n{% endraw %}{% raw %}\n~~~", "#{' ' * 500}```x", "~~~~#{" 　~~ x\t" * 50}"
      ]
    end

    it "matches the legacy Ruby reference across edge cases" do
      edge_cases.each do |input|
        expected = legacy_escape_liquid_tags_in_codeblock.call(input)
        expect(described_class.escape_liquid_tags_in_codeblock(input)).to eq(expected), input.inspect
        expect(parser.escape_liquid_tags_in_codeblock(input)).to eq(expected), input.inspect
      end
    end

    it "declines non-UTF-8, String subclasses, and invalid byte sequences so the parser keeps Ruby semantics" do
      input = "a `{% raw %}` b"
      expected = "a {% raw %}`{----% raw %----}`{% endraw %} b"

      [input.b, input.dup.force_encoding(Encoding::US_ASCII), ActiveSupport::SafeBuffer.new(input)].each do |other|
        expect(described_class.escape_liquid_tags_in_codeblock(other)).to be_nil
        result = parser.escape_liquid_tags_in_codeblock(other)
        expect(result).to eq(expected)
        expect(result.encoding).to eq(other.encoding)
      end

      expect(ForemNative::Native.escape_liquid_tags_in_codeblock("#{input}\xFF")).to be_nil
      expect { parser.escape_liquid_tags_in_codeblock("#{input}\xFF") }
        .to raise_error(ArgumentError, /invalid byte sequence/)
    end

    it "returns a new mutable UTF-8 String whether or not anything was escaped" do
      ["a `b` c".freeze, "no code here".freeze].each do |input|
        result = described_class.escape_liquid_tags_in_codeblock(input)

        expect(result).to eq(legacy_escape_liquid_tags_in_codeblock.call(input))
        expect(result).not_to equal(input)
        expect(result).not_to be_frozen
        expect(result.encoding).to eq(Encoding::UTF_8)
        expect { result << "!" }.not_to(change { input })
      end
    end

    it "passes differential equivalence across 1,000 generated code-heavy Markdown inputs" do
      rng = Random.new(424_242)
      tokens = ["`", "``", "```", "````", "`````", "~", "~~", "~~~", "~~~~", " ", "  ", "\t", "\n", "\r\n", " ",
                "　", " ", "​", "\u0085", "word", "x", "é", "🚀", "日本", "{% raw %}", "{% endraw %}",
                "{%", "%}", "{{ x }}", "{% tag %}", "```ruby\n", "~~~js\n", "\\", "|", "#"]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..40)) { tokens.sample(random: rng) }.join

        expected = legacy_escape_liquid_tags_in_codeblock.call(sample)
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(described_class.escape_liquid_tags_in_codeblock(sample)).to eq(expected), message
        expect(parser.escape_liquid_tags_in_codeblock(sample)).to eq(expected), message
      end
    end
  end
end
