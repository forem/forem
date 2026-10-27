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

  describe ".color_accent" do
    let(:legacy_accent) do
      lambda do |hex, amount|
        Color::CompareHex::ACCENT_MODIFIERS.each do |modifier|
          with_brightness = begin
            rgb = hex.match(/^#?(?<r>..)(?<g>..)(?<b>..)$/).named_captures.to_h do |key, color|
              [key.to_sym, color.hex]
            end
            format("#%<r>02x%<g>02x%<b>02x", rgb.transform_values { |color| (color * (modifier**amount)).round })
          rescue StandardError
            hex
          end
          break with_brightness if with_brightness.size == 7
        end
      end
    end

    it "matches the legacy reference across strict and malformed colors" do
      ["#ccddee", "ccddee", "#000000", "#ffffff", "#123456", "#123456\n", "#éééééé", "#🚀🚀🚀"].each do |hex|
        [1, 0, -1, 0.5, 1.25, 2, Float::INFINITY, Float::NAN].each do |amount|
          expected = legacy_accent.call(hex, amount)
          native = described_class.color_accent(hex, amount)
          expect(native).to eq(expected) unless native.nil?
          expect(Color::CompareHex.new([hex]).accent(amount)).to eq(expected)
        end
      end
    end

    it "passes differential equivalence across 1,000 generated hex colors and amounts" do
      rng = Random.new(424_242)
      hex_chars = [*"0".."9", *"a".."f", *"A".."F"]
      noise_chars = hex_chars + ["#", "-", "+", " ", "_", "x", "g", "\n", "é", "🚀"]

      1_000.times do |iteration|
        prefix = rng.rand < 0.8 ? "#" : ""
        hex = if rng.rand < 0.85
                prefix + Array.new(6) { hex_chars.sample(random: rng) }.join
              else
                prefix + Array.new(rng.rand(0..8)) { noise_chars.sample(random: rng) }.join
              end
        amount = (rng.rand * 4.0) - 0.5
        expected = legacy_accent.call(hex, amount)
        native = described_class.color_accent(hex, amount)
        actual = Color::CompareHex.new([hex]).accent(amount)
        message = "iteration #{iteration}: #{hex.inspect} ** #{amount.inspect}"
        expect(native).to eq(expected), message unless native.nil?
        expect(actual).to eq(expected), message
      end
    end
  end

  describe ".color_opacity" do
    let(:legacy_opacity) do
      lambda do |hex, alpha|
        rgb = hex.match(/^#?(?<r>..)(?<g>..)(?<b>..)$/).named_captures.to_h { |key, color| [key.to_sym, color.hex] }
        format("rgba(%<r>d, %<g>d, %<b>d, %<a>.2f)", rgb.merge(a: alpha))
      end
    end

    let(:edge_hexes) do
      [
        nil, "", "#", "#fff", "#12345", "#1234567", "##12345", "#123456", "123456", "#3B49DF", "#000000",
        "#ffffff", "#-1-1-1", "#0x0x0x", "# 1 2 3", "#12345g", "#123456\n", "\n#123456", "foo\n#123456",
        "#123456\r\n", "#éééééé", "#🚀🚀🚀", "#123456".encode("UTF-16LE"), "#123456".b, :"#123456"
      ]
    end

    let(:edge_alphas) do
      [0.1, 0.0, -0.0, 0.5, 1, 0, -1, 0.29, 0.07, 12.34, -0.1, 0.125, 0.375, 2.675, 1.005, 0.015, 0.025,
       1.0 / 3, 0.001, -0.004, 5e-324, 999_999_999.99, 1e9, 2**31, 2**40, 1e300, -1e300, Float::INFINITY,
       -Float::INFINITY, Float::NAN, Rational(1, 2), "0.5", nil]
    end

    let(:outcome) do
      lambda do |&block|
        block.call
      rescue StandardError => e
        e.class
      end
    end

    it "matches the legacy Ruby reference across edge-case hexes and alphas" do
      edge_hexes.product(edge_alphas).each do |hex, alpha|
        expected = outcome.call { legacy_opacity.call(hex, alpha) }
        native = described_class.color_opacity(hex, alpha)
        actual = outcome.call { Color::CompareHex.new([hex]).opacity(alpha) }
        message = "mismatch for #{hex.inspect} @ #{alpha.inspect}"

        expect(native).to eq(expected), message unless native.nil?
        expect(actual).to eq(expected), message
        expect(actual.encoding).to eq(expected.encoding), message if expected.is_a?(String)
      end
    end

    it "returns nil from the native function for malformed hexes and alphas that need rounding" do
      expect(ForemNative::Native.color_opacity("#123456", 0.5)).to eq("rgba(18, 52, 86, 0.50)")
      expect(ForemNative::Native.color_opacity("#123456", -0.0)).to eq("rgba(18, 52, 86, -0.00)")
      expect(ForemNative::Native.color_opacity("#123456\n", 0.5)).to be_nil
      expect(ForemNative::Native.color_opacity("#123456", 2.675)).to be_nil
      expect(ForemNative::Native.color_opacity("#123456", Float::NAN)).to be_nil
      expect(Color::CompareHex.new(["#123456"]).opacity(2.675)).to eq("rgba(18, 52, 86, 2.68)")
    end

    it "passes differential equivalence across 1,000 generated hex colors and alphas" do
      rng = Random.new(424_242)
      hex_chars = [*"0".."9", *"a".."f", *"A".."F"]
      noise_chars = hex_chars + ["#", "-", "+", " ", "_", "x", "g", "\n", "é", "🚀"]

      1_000.times do |iteration|
        prefix = rng.rand < 0.8 ? "#" : ""
        hex = if rng.rand < 0.85
                prefix + Array.new(6) { hex_chars.sample(random: rng) }.join
              else
                prefix + Array.new(rng.rand(1..8)) { noise_chars.sample(random: rng) }.join
              end
        alpha = case rng.rand(4)
                when 0 then rng.rand(-100..1_000) / 100.0
                when 1 then rng.rand(-999_999_999_999..99_999_999_999) / 100.0
                when 2 then (rng.rand * 4.0) - 1.0
                else rng.rand(-2..5)
                end

        expected = outcome.call { legacy_opacity.call(hex, alpha) }
        native = described_class.color_opacity(hex, alpha)
        message = "iteration #{iteration}: #{hex.inspect} @ #{alpha.inspect}"

        expect(native).to eq(expected), message unless native.nil?
        expect(outcome.call { Color::CompareHex.new([hex]).opacity(alpha) }).to eq(expected), message
      end
    end

    it "agrees with Ruby's %.2f for every hundredth from -20,000.00 to 20,000.00" do
      (-2_000_000..2_000_000).step(7) do |hundredths|
        alpha = hundredths / 100.0
        expect(described_class.color_opacity("#3b49df", alpha)).to eq(legacy_opacity.call("#3b49df", alpha))
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

  describe ".convert_escaped_pipes_outside_codeblocks" do
    let(:legacy_convert_escaped_pipes_outside_codeblocks) do
      lambda do |content|
        placeholder = "\x00FOREM_ESC_PIPE\x00"
        current_fence_marker = nil

        content.each_line.map do |line|
          if current_fence_marker
            fence_char = current_fence_marker[0]
            closing = /^\s*#{Regexp.escape(fence_char)}{#{current_fence_marker.length},}\s*$/
            current_fence_marker = nil if line.match?(closing)
            next line
          end

          opening_marker = line[/^\s*((`{3,}|~{3,}))/i, 1]
          if opening_marker
            current_fence_marker = opening_marker
            next line
          end

          line.gsub!(/(`+)([^`\n]*?(?:`(?!\1)[^`\n]*?)*)\1/) { |span| span.gsub('\|') { placeholder } }
          line.gsub!(/(?<!\\)\\\|/, "&#124;")
          line.gsub!(placeholder) { '\|' }
          line
        end.join
      end
    end

    let(:parser) { MarkdownProcessor::Parser.new("") }

    let(:edge_cases) do
      [
        "\\|", "a\\|b", "| a\\|b | c\\|d |\n", "leave \\\\|alone", "\\\\\\|", "\\|\\|", "`a\\|b` c\\|d",
        "`` a\\|b `` x\\|y", "``a`\\|", "`a``b\\|`", "``a`b\\|``", "`\\|", "`\\|\n\\|`", "```\na\\|b\n```\nc\\|d",
        "~~~\na\\|b\n~~~~\nc\\|d", "````\n```\na\\|b\n````\n\\|", "  ```js\n\\|\n  ```  \r\n\\|", "~~~\n\\|\n```\n\\|",
        "\t\v```\n\\|\n\f```\n\\|", "``` x\n\\|\n``` x\n\\|", "\\|\r\n`\\|`\r\n", "é\\|🚀 `日本\\|`",
        "\x00FOREM_ESC_PIPE\x00 \\|", "#{'`' * 300}\\|", "`x` #{'\\|' * 200}"
      ]
    end

    it "matches the legacy Ruby reference across edge cases" do
      edge_cases.each do |input|
        expected = legacy_convert_escaped_pipes_outside_codeblocks.call(input.dup)
        expect(described_class.convert_escaped_pipes_outside_codeblocks(input)).to eq(expected), input.inspect
        expect(parser.convert_escaped_pipes_outside_codeblocks(input)).to eq(expected), input.inspect
      end
    end

    it "declines non-UTF-8, String subclasses, and invalid byte sequences so the parser keeps Ruby semantics" do
      input = "a\\|b `c\\|d`"
      expected = "a&#124;b `c\\|d`"

      [input.b, input.dup.force_encoding(Encoding::US_ASCII), ActiveSupport::SafeBuffer.new(input)].each do |other|
        expect(described_class.convert_escaped_pipes_outside_codeblocks(other)).to be_nil
        expect(parser.convert_escaped_pipes_outside_codeblocks(other)).to eq(expected)
      end

      expect(ForemNative::Native.convert_escaped_pipes_outside_codeblocks("#{input}\xFF")).to be_nil
      expect { parser.convert_escaped_pipes_outside_codeblocks("#{input}\xFF") }
        .to raise_error(ArgumentError, /invalid byte sequence/)
    end

    it "returns a new mutable UTF-8 String whether or not anything was converted" do
      ["a\\|b".freeze, "`a\\|b`".freeze].each do |input|
        result = described_class.convert_escaped_pipes_outside_codeblocks(input)

        expect(result).to eq(legacy_convert_escaped_pipes_outside_codeblocks.call(input.dup))
        expect(result).not_to equal(input)
        expect(result).not_to be_frozen
        expect(result.encoding).to eq(Encoding::UTF_8)
        expect { result << "!" }.not_to(change { input })
      end
    end

    it "passes differential equivalence across 1,000 generated table and code-heavy Markdown inputs" do
      rng = Random.new(424_242)
      tokens = ["`", "``", "```", "````", "~", "~~", "~~~", "~~~~", "\\|", "\\|", "\\", "|", "\\\\|", " ", "\t", "\v",
                "\n", "\r\n", "a", "word", "é", "🚀", "日本", "\x00FOREM_ESC_PIPE\x00", "```js\n", "~~~\n", "  ```", "| "]

      1_000.times do |iteration|
        sample = "\\|#{Array.new(rng.rand(1..40)) { tokens.sample(random: rng) }.join}"

        expected = legacy_convert_escaped_pipes_outside_codeblocks.call(sample.dup)
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(described_class.convert_escaped_pipes_outside_codeblocks(sample)).to eq(expected), message
        expect(parser.convert_escaped_pipes_outside_codeblocks(sample)).to eq(expected), message
      end
    end
  end

  describe ".fixer_convert_new_lines" do
    let(:legacy_convert_new_lines) { ->(markdown) { markdown.gsub("\r\n", "\n") } }
    let(:fixer) { MarkdownProcessor::Fixer::Base }

    let(:edge_cases) do
      ["", "plain LF\ntext", "lone CR\r", "\r\n", "\r\r\n", "a\r\nb\r\nc", "🚀\r\n日本\né\rX"]
    end

    it "matches Ruby's gsub across line ending and Unicode edge cases" do
      edge_cases.each do |input|
        expected = legacy_convert_new_lines.call(input)
        expect(described_class.fixer_convert_new_lines(input)).to eq(expected), input.inspect
        expect(fixer.convert_new_lines(input)).to eq(expected), input.inspect
      end
      expect(described_class.fixer_convert_new_lines(nil)).to be_nil
      expect { fixer.convert_new_lines(nil) }.to raise_error(NoMethodError)
    end

    it "declines unsupported encodings, String subclasses, and invalid bytes" do
      input = "one\r\ntwo"
      [input.b, input.dup.force_encoding(Encoding::US_ASCII), ActiveSupport::SafeBuffer.new(input)].each do |other|
        expect(described_class.fixer_convert_new_lines(other)).to be_nil
        result = fixer.convert_new_lines(other)
        expect(result).to eq(legacy_convert_new_lines.call(other))
        expect(result.encoding).to eq(other.encoding)
      end

      invalid = "one\r\ntwo\xFF"
      expect(ForemNative::Native.fixer_convert_new_lines(invalid)).to be_nil
      expect(fixer.convert_new_lines(invalid)).to eq(legacy_convert_new_lines.call(invalid))
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = ["word", "\r\n", "\n", "\r", "🚀", "日本", "é", " ", "```ruby", "\t"]

      1_000.times do |iteration|
        input = Array.new(rng.rand(0..100)) { tokens.sample(random: rng) }.join.force_encoding(Encoding::UTF_8)
        expected = legacy_convert_new_lines.call(input)
        message = "iteration #{iteration}: #{input.inspect}"
        expect(described_class.fixer_convert_new_lines(input)).to eq(expected), message
        expect(fixer.convert_new_lines(input)).to eq(expected), message
      end
    end
  end

  describe ".fixer_add_quotes_to_section" do
    let(:legacy_add_quotes_to_section) do
      lambda do |markdown, section|
        markdown.sub(/-{3}.*?-{3}/m) do |front_matter|
          front_matter.gsub(/#{section}: ?(?<content>.*?)(\r\n|\n)/m) do |target|
            captured_text = Regexp.last_match("content")
            if captured_text.scan(/(^".*"$|^'.*'$)/).empty?
              "#{section}: \"#{captured_text.gsub(/(?<!\\)"/, '\\"')}\"\n"
            else
              target
            end
          end
        end
      end
    end

    let(:fixer) { MarkdownProcessor::Fixer::Base }

    let(:edge_cases) do
      [
        "", "no front matter", "---\ntitle: Hello\n---\nbody", "---\ntitle: a \"b\" \\\"c\\\"\n---",
        "---\ntitle: \"Hi\"\r\ndescription: 'x'\n---", "---\ntitle: \"\n---", "---\ntitle: '\n---",
        "---\ntitle: \"x'\n---", "---\r\ntitle:Hi\r\n---", "---\ntitle:\n---", "---\ntitle: \n---",
        "---\ntitle:  two\n---", "---\ntitle: a\rb\r\r\n---", "---\nsubtitle: a\ntitle: b\n---\ntitle: c\n",
        "---\ntitletitle: x\n---", "---\ntitle x\n---", "---title: x---\n", "---\ntitle: x ---\ntitle: y\n",
        "intro ----\ntitle: x\n---", "-----title: x\n", "------\ntitle: x\n---",
        "---\ntitle: 日本語 \"🎉\"\n---", "---\ndescription: it's \"great\"\ntitle: 'ok'\n---\n# Heading\n"
      ]
    end

    it "matches the legacy Ruby reference across edge cases" do
      sections = %w[title description]
      edge_cases.each do |input|
        sections.each do |section|
          expected = legacy_add_quotes_to_section.call(input, section)
          message = "#{section}: #{input.inspect}"
          expect(described_class.fixer_add_quotes_to_section(input, section)).to eq(expected), message
          expect(fixer.add_quotes_to_section(input, section: section)).to eq(expected), message
        end
      end
    end

    it "declines non-UTF-8, String subclasses, invalid bytes, and non-word sections so Fixer keeps Ruby semantics" do
      input = "---\ntitle: a \"b\"\n---"
      expected = "---\ntitle: \"a \\\"b\\\"\"\n---"

      [input.b, input.dup.force_encoding(Encoding::US_ASCII), ActiveSupport::SafeBuffer.new(input)].each do |other|
        expect(described_class.fixer_add_quotes_to_section(other, "title")).to be_nil
        expect(fixer.add_quotes_to_section(other, section: "title")).to eq(expected)
      end

      expect(described_class.fixer_add_quotes_to_section(input, "ti.le")).to be_nil
      expect(fixer.add_quotes_to_section(input, section: "ti.le"))
        .to eq(legacy_add_quotes_to_section.call(input, "ti.le"))
      expect(ForemNative::Native.fixer_add_quotes_to_section("#{input}\xFF", "title")).to be_nil
      expect { fixer.add_quotes_to_section("#{input}\xFF", section: "title") }
        .to raise_error(ArgumentError, /invalid byte sequence/)
    end

    it "returns a new mutable UTF-8 String whether or not anything was quoted" do
      ["---\ntitle: \"a\"\n---".freeze, "---\ntitle: a\n---".freeze].each do |input|
        result = described_class.fixer_add_quotes_to_section(input, "title")

        expect(result).to eq(legacy_add_quotes_to_section.call(input, "title"))
        expect(result).not_to equal(input)
        expect(result).not_to be_frozen
        expect(result.encoding).to eq(Encoding::UTF_8)
        expect { result << "!" }.not_to(change { input })
      end
    end

    it "passes differential equivalence across 1,000 generated front matter inputs" do
      rng = Random.new(424_242)
      tokens = ["---", "---\n", "-", "--", "\n", "\r\n", "\r", "title", "title:", "title: ", "description: ", ":", " ",
                "\"", "'", "\\", "\\\"", "sub", "a", "word", "é", "🚀", "日本", "\ntitle: ", "\ndescription:"]

      1_000.times do |iteration|
        sample = "---\n#{Array.new(rng.rand(1..40)) { tokens.sample(random: rng) }.join}"
        section = rng.rand(2).zero? ? "title" : "description"

        expected = legacy_add_quotes_to_section.call(sample, section)
        message = "iteration #{iteration} (#{section}): #{sample.inspect}"
        expect(described_class.fixer_add_quotes_to_section(sample, section)).to eq(expected), message
        expect(fixer.add_quotes_to_section(sample, section: section)).to eq(expected), message
      end
    end
  end

  describe ".fixer_split_tags" do
    let(:legacy_split_tags) do
      lambda do |markdown|
        markdown.gsub(/\ntags:.*\n/) do |tags|
          tags.split(" #").join(",").delete("#").gsub(":,", ": ")
        end
      end
    end

    let(:fixer) { MarkdownProcessor::Fixer::Base }

    let(:edge_cases) do
      [
        "", "no tags", "tags: #a #b\n", "x\ntags: #a #b", "---\ntags: #a #b #c\n---", "---\ntags: a, b\n---",
        "---\ntags:#a#b\n", "x\ntags: # #a ##b\n", "x\ntags::# a\n", "x\ntags: #\n", "x\ntags:\n",
        "\ntags: #a\ntags: #b\n\ntags: #c\n", "x\r\ntags: #日本 #🚀\r\nbody #x\n", "\nTags: #a\n",
        "---\ntitle: Hi\ntags: #ruby #rails\n---\n# Heading\n\ntags: #not #front #matter\n"
      ]
    end

    it "matches the legacy Ruby reference across edge cases" do
      edge_cases.each do |input|
        expected = legacy_split_tags.call(input)
        expect(described_class.fixer_split_tags(input)).to eq(expected), input.inspect
        expect(fixer.split_tags(input)).to eq(expected), input.inspect
      end
    end

    it "declines non-UTF-8, String subclasses, and invalid bytes so Fixer keeps Ruby semantics" do
      input = "x\ntags: #a #b\n"

      [input.b, input.dup.force_encoding(Encoding::US_ASCII), ActiveSupport::SafeBuffer.new(input)].each do |other|
        expect(described_class.fixer_split_tags(other)).to be_nil
        expect(fixer.split_tags(other)).to eq("x\ntags: a,b\n")
      end

      expect(ForemNative::Native.fixer_split_tags("#{input}\xFF")).to be_nil
      expect { fixer.split_tags("#{input}\xFF") }.to raise_error(ArgumentError, /invalid byte sequence/)
    end

    it "returns a new mutable UTF-8 String whether or not anything was split" do
      ["no tags".freeze, "x\ntags: #a\n".freeze].each do |input|
        result = described_class.fixer_split_tags(input)

        expect(result).to eq(legacy_split_tags.call(input))
        expect(result).not_to equal(input)
        expect(result).not_to be_frozen
        expect(result.encoding).to eq(Encoding::UTF_8)
        expect { result << "!" }.not_to(change { input })
      end
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = ["\ntags:", "\ntags: ", "tags:", "\n", "\r\n", "\r", " ", "#", " #", "##", ",", ":", ":,", "a",
                "ruby", "é", "🚀", "日本", "---\n", "\nTags:"]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..40)) { tokens.sample(random: rng) }.join

        expected = legacy_split_tags.call(sample)
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(described_class.fixer_split_tags(sample)).to eq(expected), message
        expect(fixer.split_tags(sample)).to eq(expected), message
      end
    end
  end

  describe ".fixer_lowercase_published" do
    let(:legacy_lowercase_published) do
      lambda do |markdown|
        markdown.gsub(/-{3}.*?-{3}/m) do |front_matter|
          front_matter.gsub(/^published: /i, "published: ")
        end
      end
    end

    let(:fixer) { MarkdownProcessor::Fixer::Base }

    let(:edge_cases) do
      [
        "", "no front matter", "---\nPublished: true\nPUBLISHED: false\n---\nPublished: x\n",
        "---\na: 1\n---\n\n---\nPuBlIsHeD: y\n---", "---\nPublished: ---", "---Published: x\n---",
        "--- Published: x\n---", "---\n Published: x\n---", "---\nPublished:x\n---", "---\nPublished : x\n---",
        "---\npublished: x\n---", "---\nPubli---shed: x\n", "---\nPublished:---", "---\r\nx\rPublished: x\n---",
        "-----\nPublished: x", "------\nPublished: x\n---", "---\r\nPublished: x\r\n---",
        "---\nPubliſhed: 日本\nPUBLIſHED: 🎉\n---", "---\nPubliſshed: x\nPublishéd: y\n---"
      ]
    end

    it "matches the legacy Ruby reference across edge cases" do
      edge_cases.each do |input|
        expected = legacy_lowercase_published.call(input)
        expect(described_class.fixer_lowercase_published(input)).to eq(expected), input.inspect
        expect(fixer.lowercase_published(input)).to eq(expected), input.inspect
      end
    end

    it "declines non-UTF-8, String subclasses, and invalid bytes so Fixer keeps Ruby semantics" do
      input = "---\nPublished: true\n---"

      [input.b, input.dup.force_encoding(Encoding::US_ASCII), ActiveSupport::SafeBuffer.new(input)].each do |other|
        expect(described_class.fixer_lowercase_published(other)).to be_nil
        expect(fixer.lowercase_published(other)).to eq("---\npublished: true\n---")
      end

      expect(ForemNative::Native.fixer_lowercase_published("#{input}\xFF")).to be_nil
      expect { fixer.lowercase_published("#{input}\xFF") }.to raise_error(ArgumentError, /invalid byte sequence/)
    end

    it "returns a new mutable UTF-8 String whether or not anything was lowercased" do
      ["---\npublished: x\n---".freeze, "---\nPublished: x\n---".freeze].each do |input|
        result = described_class.fixer_lowercase_published(input)

        expect(result).to eq(legacy_lowercase_published.call(input))
        expect(result).not_to equal(input)
        expect(result).not_to be_frozen
        expect(result.encoding).to eq(Encoding::UTF_8)
        expect { result << "!" }.not_to(change { input })
      end
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = ["---", "---\n", "\n---", "--", "-", "\n", "\r\n", "\r", " ", "\nPublished: ", "published: ",
                "Published: ", "PUBLISHED: ", "pUbLiShEd: ", "Publiſhed: ", "publi", "shed: ", "Published:",
                "published", ": ", "true", "é", "🚀", "日本"]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..40)) { tokens.sample(random: rng) }.join

        expected = legacy_lowercase_published.call(sample)
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(described_class.fixer_lowercase_published(sample)).to eq(expected), message
        expect(fixer.lowercase_published(sample)).to eq(expected), message
      end
    end
  end

  describe ".fixer_underscores_in_usernames" do
    let(:legacy_underscores_in_usernames) do
      lambda do |markdown|
        regexp = /(?<!`)@_\w+_/
        next markdown unless markdown.match?(regexp)

        traverser = MarkdownProcessor::Traverser.new(markdown)
        traverser.each do |line|
          next if traverser.in_codeblock?

          line.scan(regexp).each { |to_escape| line.sub!(to_escape, to_escape.gsub("_", "\\_")) }
        end.join
      end
    end

    let(:fixer) { MarkdownProcessor::Fixer::Base }

    let(:edge_cases) do
      [
        "", "@_xy_", "@_x_y_", "@__", "@___", "@_a", "@_a_b", "_make this cursive_", "a@_b_c@_d_", "@_a_@_b_",
        "@@_a_", "`@_a_`", "`@_a_ @_a_", "x`@_a_b_ @_a_", "@_a_\r\n@_b_", "@_é_ @_aé_x_", "日本 @_🎉_ @_日_本_",
        "@_dev_\n```ruby\n@_in_code_\n```\n@_out_\n", "``` @_fence_\n@_in_\n```\n", "```@_fence_\n@_in_\n```\n",
        "```\n@_open_forever_\n", "``` ```\n@_a_\n", "\n\n@_a_\n\n", "@_a_\r@_b_"
      ]
    end

    it "matches the legacy Ruby reference across edge cases" do
      edge_cases.each do |input|
        expected = legacy_underscores_in_usernames.call(input)
        expect(described_class.fixer_underscores_in_usernames(input)).to eq(expected), input.inspect
        expect(fixer.underscores_in_usernames(input)).to eq(expected), input.inspect
      end
    end

    it "declines non-UTF-8, String subclasses, and invalid bytes so Fixer keeps Ruby semantics" do
      input = "@_dev_ `@_code_`"

      [input.b, input.dup.force_encoding(Encoding::US_ASCII), ActiveSupport::SafeBuffer.new(input)].each do |other|
        expect(described_class.fixer_underscores_in_usernames(other)).to be_nil
        expect(fixer.underscores_in_usernames(other)).to eq("@\\_dev\\_ `@_code_`")
      end

      expect(ForemNative::Native.fixer_underscores_in_usernames("#{input}\xFF")).to be_nil
      expect { fixer.underscores_in_usernames("#{input}\xFF") }.to raise_error(ArgumentError, /invalid byte sequence/)
    end

    it "returns the input itself when nothing is escaped, like the legacy early return" do
      input = "no usernames".freeze

      expect(described_class.fixer_underscores_in_usernames(input)).to equal(input)
      expect(legacy_underscores_in_usernames.call(input)).to equal(input)
    end

    it "returns a new mutable UTF-8 String when a username is escaped" do
      input = "@_dev_".freeze
      result = described_class.fixer_underscores_in_usernames(input)

      expect(result).to eq(legacy_underscores_in_usernames.call(input))
      expect(result).not_to be_frozen
      expect(result.encoding).to eq(Encoding::UTF_8)
      expect { result << "!" }.not_to(change { input })
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = ["@_", "@", "_", "__", "a", "Z9", "dev", "`", "```", "```ruby", "\n", "\r\n", "\r", " ", "@_dev_",
                "@_x_y_", "`@_a_", "\\", "-", "é", "🚀", "日本"]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..40)) { tokens.sample(random: rng) }.join

        expected = legacy_underscores_in_usernames.call(sample)
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(described_class.fixer_underscores_in_usernames(sample)).to eq(expected), message
        expect(fixer.underscores_in_usernames(sample)).to eq(expected), message
      end
    end
  end

  describe ".convert_code_tags_to_triple_backticks" do
    let(:legacy_convert_code_tags_to_triple_backticks) do
      lambda do |content|
        next content unless /^<code>$/.match?(content)
        next content if content.include?("<code>") && content.include?("<pre>")

        content.gsub(%r{^</?code>$}, "\n```\n")
      end
    end

    let(:parser) { MarkdownProcessor::Parser.new("") }

    let(:edge_cases) do
      [
        "", "<code>", "</code>", "<code></code>", "<code>\n</code>", "a<code>\n</code>", "x\n<code>\r\n</code>\n",
        "<code>\r</code>", "\r\n<code>\r\n<code>\n</code>\r\n", "<code>\nhi\n</code>\n</code>x\n<pre>z",
        "<pre>\n<code>\n code \n</code>\n</pre>", "<code>\n<PRE>\n</code>", "\n<code>\n\n</code>\n",
        "\n</code>\n<code>\n", "é\n<code>\n日本\n</code>", "<code>\n</CODE>\n<code >\n<//code>\n</code>",
        "🚀<code>\n<code>🚀\n<code>\n", "inline <code>x</code> only\n"
      ]
    end

    it "matches the legacy Ruby reference across edge cases" do
      edge_cases.each do |input|
        expected = legacy_convert_code_tags_to_triple_backticks.call(input)
        expect(described_class.convert_code_tags_to_triple_backticks(input)).to eq(expected), input.inspect
        expect(parser.convert_code_tags_to_triple_backticks(input)).to eq(expected), input.inspect
      end
    end

    it "declines non-UTF-8, String subclasses, and invalid bytes so the parser keeps Ruby semantics" do
      input = "<code>\nx\n</code>"

      [input.b, input.dup.force_encoding(Encoding::US_ASCII), ActiveSupport::SafeBuffer.new(input)].each do |other|
        expect(described_class.convert_code_tags_to_triple_backticks(other)).to be_nil
        expect(parser.convert_code_tags_to_triple_backticks(other)).to eq("\n```\n\nx\n\n```\n")
      end

      expect(ForemNative::Native.convert_code_tags_to_triple_backticks("#{input}\xFF")).to be_nil
      expect { parser.convert_code_tags_to_triple_backticks("#{input}\xFF") }
        .to raise_error(ArgumentError, /invalid byte sequence/)
    end

    it "returns the input itself when nothing is converted, like the legacy early returns" do
      ["no code tags".freeze, "<pre>\n<code>\n</code>".freeze].each do |input|
        expect(described_class.convert_code_tags_to_triple_backticks(input)).to equal(input)
        expect(legacy_convert_code_tags_to_triple_backticks.call(input)).to equal(input)
      end
    end

    it "returns a new mutable UTF-8 String when code tags are converted" do
      input = "<code>\nx\n</code>".freeze
      result = described_class.convert_code_tags_to_triple_backticks(input)

      expect(result).to eq(legacy_convert_code_tags_to_triple_backticks.call(input))
      expect(result).not_to be_frozen
      expect(result.encoding).to eq(Encoding::UTF_8)
      expect { result << "!" }.not_to(change { input })
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = ["<code>", "</code>", "<code>\n", "\n</code>", "<pre>", "</pre>", "<", ">", "/", "code", "<code",
                "\n", "\r\n", "\r", " ", "x", "```", "é", "🚀", "日本"]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..30)) { tokens.sample(random: rng) }.join

        expected = legacy_convert_code_tags_to_triple_backticks.call(sample)
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(described_class.convert_code_tags_to_triple_backticks(sample)).to eq(expected), message
        expect(parser.convert_code_tags_to_triple_backticks(sample)).to eq(expected), message
      end
    end
  end

  describe ".markdown_xss_attempt" do
    let(:legacy_markdown_xss_attempt) do
      lambda do |markdown|
        markdown.gsub(MarkdownProcessor::Parser::CODE_BLOCKS_REGEX, "")
          .match?(Regexp.union(MarkdownProcessor::Parser::BAD_XSS_REGEX))
      end
    end

    let(:parser) { MarkdownProcessor::Parser.new("") }

    let(:edge_cases) do
      [
        "", "plain text", "src='data", "src=\"&\"", "SRC='DATA", "src='DatA:text/html;base64:xxxx'", "src= 'data",
        "src='dat", "src=`data", "src=", "rc='data", "ſrc='data", "ſRC=\"&", "srcſ='data", "data:text/html,",
        "DATA:TEXT/HTML;", "data:text/html", "data:text/html ,", "```const data = 'data:text/html';```",
        "```\n src='data \n```", "`` src='data ``", "` src='data `", "~~~\n src='data \n~~~",
        "```\n  code block 1\n```\n\nsrc='data\n\n```\n  code block 2\n```\n", "sr`x`c='data", "src=``x``'data",
        "src=~~~x~~~\"&", "data:```x```text/html;", "````src='data````", "````src='data", "~~src='data~~",
        "~~~~src='data~~~", "``` x `` src='data", "`` x ` src='data `", "`unclosed src='data", "ſ`x`rc='data",
        "`ſ`rc='data", "日本語 src='データ", "😀src='data😀", "\r\n`x`\r\nsrc='&"
      ]
    end

    def expect_parser_check(parser, input, expected, message)
      if expected
        expect { parser.catch_xss_attempts(input) }.to raise_error(ArgumentError), message
      else
        expect { parser.catch_xss_attempts(input) }.not_to raise_error, message
      end
    end

    it "matches the legacy Ruby reference across edge cases" do
      edge_cases.each do |input|
        expected = legacy_markdown_xss_attempt.call(input)
        expect(described_class.markdown_xss_attempt(input)).to eq(expected), input.inspect
        expect_parser_check(parser, input, expected, input.inspect)
      end
    end

    it "declines non-UTF-8, String subclasses, and invalid bytes so the parser keeps Ruby semantics" do
      input = "src='data"

      [input.b, input.dup.force_encoding(Encoding::US_ASCII), ActiveSupport::SafeBuffer.new(input)].each do |other|
        expect(described_class.markdown_xss_attempt(other)).to be_nil
        expect { parser.catch_xss_attempts(other) }.to raise_error(ArgumentError)
      end
      expect { parser.catch_xss_attempts("`#{input}`".b) }.not_to raise_error

      expect(ForemNative::Native.markdown_xss_attempt("plain\xFF")).to be_nil
      expect { parser.catch_xss_attempts("plain\xFF") }.to raise_error(ArgumentError, /invalid byte sequence/)
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = ["src='data", "SrC=\"&", "ſrc='", "data:text/html,", "DATA:TEXT/HTML;", "src", "ſ", "rc", "=", "'",
                "\"", "data", "&", ":", "text/html", ";", "`", "``", "```", "~~~", " ", "\n", "\r\n", "x", "é",
                "🚀", "日本"]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..30)) { tokens.sample(random: rng) }.join

        expected = legacy_markdown_xss_attempt.call(sample)
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(described_class.markdown_xss_attempt(sample)).to eq(expected), message
        expect_parser_check(parser, sample, expected, message)
      end
    end
  end

  describe ".strip_default_image_alt_text" do
    let(:legacy_strip_default_image_alt_text) do
      ->(content) { content.gsub(/!\[Image Description\]/i, "![ ]") }
    end

    let(:parsed_content) do
      ->(content) { MarkdownProcessor::Parser.new(content).instance_variable_get(:@content) }
    end

    let(:edge_cases) do
      [
        "", "![", "![Image Description](x.png)", "![image description]", "![IMAGE DESCRIPTION]![Image Description]",
        "!![Image Description]", "![Image Description", "![Image  Description]", "![Image Deſcription](a)",
        "![Image DeſſCription]", "![ Image Description]", "!\\[Image Description]", "日本![iMaGe dEsCrIpTiOn]🚀",
        "![Image Description]]", "[![Image Description](a)](b)", "![Image Descriptions]", "![Image\nDescription]",
        "![Image Descriptioñ]", "![ImageKescription]", "![İmage Description]", "![ımage Description]",
        "x\r\n![Image Description](a)\r\n![alt](b)\n"
      ]
    end

    it "matches the legacy Ruby reference across edge cases" do
      edge_cases.each do |input|
        expected = legacy_strip_default_image_alt_text.call(input)
        expect(described_class.strip_default_image_alt_text(input)).to eq(expected), input.inspect
        expect(parsed_content.call(input)).to eq(expected), input.inspect
      end
    end

    it "treats a nil body as empty like the legacy initializer" do
      expect(parsed_content.call(nil)).to eq("")
    end

    it "declines non-UTF-8, String subclasses, and invalid bytes so the parser keeps Ruby semantics" do
      input = "![Image Description](x)"

      [input.b, input.dup.force_encoding(Encoding::US_ASCII), ActiveSupport::SafeBuffer.new(input)].each do |other|
        expect(described_class.strip_default_image_alt_text(other)).to be_nil
        expect(parsed_content.call(other)).to eq("![ ](x)")
      end

      expect(ForemNative::Native.strip_default_image_alt_text("#{input}\xFF")).to be_nil
      expect { MarkdownProcessor::Parser.new("#{input}\xFF") }.to raise_error(ArgumentError, /invalid byte sequence/)
    end

    it "returns a new mutable UTF-8 String, like gsub, whether or not anything matched" do
      ["no default alt text".freeze, "![Image Description](x)".freeze].each do |input|
        result = described_class.strip_default_image_alt_text(input)

        expect(result).to eq(legacy_strip_default_image_alt_text.call(input))
        expect(result).not_to equal(input)
        expect(result).not_to be_frozen
        expect(result.encoding).to eq(Encoding::UTF_8)
        expect { result << "!" }.not_to(change { input })
      end
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = ["![", "!", "[", "]", "![Image Description]", "Image", "image", "IMAGE", "iMaGe", " ", "Description",
                "DESCRIPTION", "Deſcription", "Descriptio", "description]", "ſ", "s", "S", "(x)", "\n", "\r\n",
                "é", "🚀", "日本", "Image Description]"]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..30)) { tokens.sample(random: rng) }.join

        expected = legacy_strip_default_image_alt_text.call(sample)
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(described_class.strip_default_image_alt_text(sample)).to eq(expected), message
        expect(parsed_content.call(sample)).to eq(expected), message
      end
    end
  end

  describe ".cloudflare_image_url" do
    let(:legacy_cloudflare_image_url) do
      lambda do |domain, directory, width, height, fit, img_src, src|
        template = Addressable::Template.new("https://{domain}/{directory}/image/{options*}/{src}")
        options = { width: width, height: height, fit: fit, gravity: "auto" }
        options[:format] = "auto" unless img_src&.match?(/\.(gif|webp)(\?.*)?$/i)
        template.expand(domain: domain, directory: directory, options: options, src: src).to_s
      end
    end

    let(:domain) { "images.example.com" }

    let(:optimizer_cloudflare) do
      lambda do |img_src, **kwargs|
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_IMAGES_DOMAIN").and_return(domain)
        Images::Optimizer.cloudflare(img_src, **kwargs)
      end
    end

    let(:edge_cases) do
      [
        nil, "", "https://i.imgur.com/fKYKgo4.png", "https://x.com/a.gif", "https://x.com/a.GIF?w=1", "a.webp",
        "https://x.com/a.WebP?", "https://x.com/a.gif\nmore", "https://x.com/a.gif\r\n", "https://x.com/a.gifv",
        "https://x.com/a.gif#frag", "https://x.com/agif", "a b/c?d=e&f=g#h", "https://x.com/é.png", "ñ~-._!*'()",
        "https://x.com/a.ġif", "\u02FF", "https://images.example.com/cdn-cgi/image/width=1/https%3A%2F%2Fa.com%2Fb.png"
      ]
    end

    it "matches the legacy Ruby reference across edge cases" do
      [nil, "", "media2.dev.to", "a:b@c"].product([nil, 1000, -5, "880", ""], %w[cover scale-down]) do |dom, w, fit|
        edge_cases.each do |img_src|
          expected = legacy_cloudflare_image_url.call(dom, "cdn-cgi", w, 420, fit, img_src, img_src)
          actual = described_class.cloudflare_image_url(dom, "cdn-cgi", w, 420, fit, img_src, img_src)
          expect(actual).to eq(expected), [dom, w, fit, img_src].inspect
        end
      end
    end

    it "keeps Images::Optimizer.cloudflare output identical, including nested Cloudflare URLs" do
      kwarg_sets = [{ width: 821, height: 505, crop: "limit" }, { width: 821, crop: "crop" }, {}]
      edge_cases.product(kwarg_sets) do |img_src, kwargs|
        fit = kwargs[:crop] == "crop" ? "cover" : "scale-down"
        src = img_src&.start_with?("https://#{domain}/cdn-cgi/image") ? "https://a.com/b.png" : img_src
        expected = legacy_cloudflare_image_url.call(domain, "cdn-cgi", kwargs[:width], kwargs[:height], fit, img_src,
                                                    src)
        expect(optimizer_cloudflare.call(img_src, **kwargs)).to eq(expected), [img_src, kwargs].inspect
      end
    end

    it "declines values Addressable would convert or normalize so Images::Optimizer keeps Ruby semantics" do
      [
        [1000.0, "https://x.com/a.png"], [:wide, "https://x.com/a.png"], [2**64, "https://x.com/a.png"],
        [1, "https://x.com/e\u0301.png"], [1, "https://x.com/日本.png"], [1, "https://x.com/😀.gif"],
        [1, "https://x.com/a.png".b], [1, "https://x.com/\xFF.png"]
      ].each do |width, img_src|
        expect(described_class.cloudflare_image_url(domain, "cdn-cgi", width, 1, "cover", img_src, img_src)).to be_nil

        next unless img_src.valid_encoding?

        expected = legacy_cloudflare_image_url.call(domain, "cdn-cgi", width, nil, "scale-down", img_src, img_src)
        expect(optimizer_cloudflare.call(img_src, width: width)).to eq(expected), [width, img_src].inspect
      end
    end

    it "accepts ActiveSupport::SafeBuffer sources like Addressable" do
      img_src = ActiveSupport::SafeBuffer.new("https://x.com/a b.gif")
      expected = legacy_cloudflare_image_url.call(domain, "cdn-cgi", 1, 2, "cover", img_src, img_src)

      expect(described_class.cloudflare_image_url(domain, "cdn-cgi", 1, 2, "cover", img_src, img_src)).to eq(expected)
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = ["https://", "x.com", "/", ".", "gif", "GIF", "webp", "WeBp", ".gif", ".webp", ".GiF", ".WEBP", "png",
                "?", "#", "&", "=", " ", "%", "+", "\n", "\r", "~", "-", "_", "é", "ñ", "\u02FF", "\u0300", "日本",
                "🚀", "a", "Z", "9", ":", "@"]
      values = [nil, "", 0, 1000, -1, "880", "auto", "a b"]

      1_000.times do |iteration|
        img_src = Array.new(rng.rand(1..12)) { tokens.sample(random: rng) }.join
        src = rng.rand < 0.1 ? nil : img_src
        args = [[nil, "", "media2.dev.to", "a:b"].sample(random: rng), %w[cdn-cgi dynamic].sample(random: rng),
                values.sample(random: rng), values.sample(random: rng), %w[cover scale-down].sample(random: rng),
                img_src, src]

        expected = legacy_cloudflare_image_url.call(*args)
        actual = described_class.cloudflare_image_url(*args)
        message = "iteration #{iteration}: #{args.inspect}"
        if img_src.match?(/[\u0300-\u{10FFFF}]/)
          expect(actual).to be_nil, message
        else
          expect(actual).to eq(expected), message
        end

        kwargs = { width: args[2], height: args[3], crop: args[4] == "cover" ? "crop" : "limit" }
        expect(optimizer_cloudflare.call(img_src, **kwargs))
          .to eq(legacy_cloudflare_image_url.call(domain, "cdn-cgi", *args[2..4], img_src, img_src)), message
      end
    end
  end

  describe ".normalize_url" do
    let(:legacy_normalize_url) { ->(url) { Addressable::URI.parse(url).normalize.to_s } }

    let(:edge_cases) do
      [
        "https://media2.dev.to/dynamic/image/quality=100/https://dev-to-uploads.s3.amazonaws.com/uploads/logo.png",
        "https://media2.dev.to/image/width=190/https%3A%2F%2Fa.com%2Flogo.png", "/assets/12-abc123.png",
        "HTTPS://Example.COM", "http://a.com?x=1", "https://a.com./x", "https://a.com../x", "https://./x",
        "https://a.com:443/x", "http://a.com:080/x", "http://a.com:/x", "http://a.com:0/x", "http://a.com:08080/x",
        "http://a.com:443/x", "/a%41%2f%7e%25%zz%", "/a\"b<c>{d}|e^`\\", "/a[b]", "/a%3F%23", "/a?b;c&d=%3d&e+f%2bg%2B",
        "/a?%252b%25", "/a?", "/a?&", "/a?%26", "/a#", "/a#b#c?/%41", "/a?#b", "https://my_bucket.s3.amazonaws.com/a.png"
      ]
    end

    it "matches Addressable normalization across edge cases" do
      edge_cases.each do |url|
        actual = described_class.normalize_url(url)
        expect(actual).to eq(legacy_normalize_url.call(url)), url.inspect
        expect(actual.encoding).to eq(Encoding::UTF_8)
      end
    end

    it "declines URLs whose normalization needs Addressable" do
      [
        "", "relative.png", "//cdn.example.com/a.png", "ftp://a.com/x", "feed:http://a.com", "data:image/png;base64,A",
        "https://user@a.com/x", "https://[::1]/x", "https:///x", "https:/a.com/x", "https://a b.com/x",
        "https://a.com/ x", "https://a.com/x\n", "https://www.火.dev/IMAGE.png", "https://a.com/%C3%A9",
        "https://a.com/x?%80", "https://a.com:12a/x", "https://a.com/./x", "https://a.com/x/..", "/%2E%2E/x",
        "https://a%41.com/x", "https://a.com/x".encode("UTF-16LE"), "https://a.com/\xFF",
        ActiveSupport::SafeBuffer.new("https://a.com/x"), nil
      ].each do |url|
        expect(described_class.normalize_url(url)).to be_nil, url.inspect
      end
    end

    it "passes differential equivalence across 1,000 accepted generated inputs" do
      rng = Random.new(424_242)
      prefixes = ["https://a.com", "http://Ex.ample.com:8080", "/", "https://media2.dev.to", "HTTPS://Dev.TO.", ""]
      tokens = ["/", "//", "?", "#", "&", ";", "=", "+", "%", "%2b", "%2B", "%2F", "%41", "%7E", "%25", "%3A",
                "%20", "%3F", "%23", "%26", "%00", "%zz", "%4", ".", "..", ":", ":443", ":0", "@", "a", "B", "9", "-",
                "_", "~", "!", "$", "'", "(", ")", "*", ",", "[", "]", "\"", "<", ">", "{", "}", "|", "\\", "^", "`",
                ".com", "png"]
      accepted = 0

      10_000.times do |iteration|
        url = prefixes.sample(random: rng) + Array.new(rng.rand(1..12)) { tokens.sample(random: rng) }.join
        actual = described_class.normalize_url(url)
        next if actual.nil?

        accepted += 1
        expect(actual).to eq(legacy_normalize_url.call(url)), "iteration #{iteration}: #{url.inspect}"
        break if accepted == 1_000
      end
      expect(accepted).to eq(1_000)
    end
  end

  describe ".join_url" do
    let(:legacy_join_url) { ->(base, uri) { Addressable::URI.parse(base).join(uri).normalize.to_s } }

    let(:edge_cases) do
      [
        ["https://dev.to", ""], ["https://dev.to", "terms"], ["https://dev.to", "/terms"],
        ["https://dev.to", "?a=1"], ["https://dev.to", "#x"], ["https://dev.to", "x?y#z"], ["https://dev.to", "/x?"],
        ["https://dev.to", "/x#"], ["https://dev.to", "/a:b"], ["https://dev.to", "/a//b"],
        ["https://dev.to", "/t/c%2B%2B/page/2"], ["https://dev.to", "ben/comment/1abc"],
        ["https://dev.to", "/ben/my-post-1abc#comment-2xyz"], ["https://dev.to", "/enter?state=new-user"],
        ["http://localhost:3000", "/a?b"], ["https://Dev.To.", "terms"], ["HTTPS://dev.to:443", "x"],
        ["https://community.example.com", "/sitemap-index.xml"]
      ]
    end

    it "matches Addressable join + normalization across edge cases" do
      edge_cases.each do |base, uri|
        actual = described_class.join_url(base, uri)
        expect(actual).to eq(legacy_join_url.call(base, uri)), [base, uri].inspect
        expect(actual.encoding).to eq(Encoding::UTF_8)
      end
    end

    it "declines joins whose resolution or normalization needs Addressable" do
      [
        ["https://dev.to/base", "x"], ["https://dev.to?q", "x"], ["https://dev.to#f", "x"], ["https://", "x"],
        ["ftp://dev.to", "x"], ["dev.to", "x"], ["https://dev.to", "//x.com/a"], ["https://dev.to", "https://other.com/A"],
        ["https://dev.to", "a:b"], ["https://dev.to", "/a/../b"], ["https://dev.to", "a/./b"], ["https://dev.to", ".."],
        ["https://dev.to", "%2E%2E/x"], ["https://dev.to", "/a b"], ["https://dev.to", "/café"],
        ["https://user@dev.to", "x"], ["https://dev.to", "/x".encode("UTF-16LE")], ["https://dev.to", "/\xFF"],
        ["https://dev.to", ActiveSupport::SafeBuffer.new("/x")], ["https://dev.to", Addressable::URI.parse("/x")],
        ["https://dev.to", nil], [nil, "/x"]
      ].each do |base, uri|
        expect(described_class.join_url(base, uri)).to be_nil, [base, uri].inspect
      end
    end

    it "passes differential equivalence across 1,000 accepted generated inputs" do
      rng = Random.new(424_242)
      bases = ["https://dev.to", "http://localhost:3000", "HTTPS://Dev.TO.", "https://a.com:8080", "http://x.dev:80"]
      tokens = ["/", "//", "?", "#", "&", ";", "=", "+", "%", "%2b", "%2B", "%2F", "%41", "%7E", "%25", "%3A", "%20",
                "%3F", "%23", "%2E", "%zz", ".", "..", ":", "@", "a", "B", "9", "-", "_", "~", "!", "$", "'", "(", ")",
                "*", ",", "[", "]", "\"", "<", ">", "{", "}", "|", "\\", "^", "`", "comment", "t", "page"]
      accepted = 0

      10_000.times do |iteration|
        base = bases.sample(random: rng)
        uri = Array.new(rng.rand(1..12)) { tokens.sample(random: rng) }.join
        actual = described_class.join_url(base, uri)
        next if actual.nil?

        accepted += 1
        expect(actual).to eq(legacy_join_url.call(base, uri)), "iteration #{iteration}: #{[base, uri].inspect}"
        break if accepted == 1_000
      end
      expect(accepted).to eq(1_000)
    end
  end

  describe ".quickie_title_html" do
    let(:legacy_quickie_title_html) do
      lambda do |title, truncate_for_feed|
        processed_title = truncate_for_feed ? title.split("\n").first(6).join("\n") : title.dup
        processed_title.gsub!(/\n\s*\n/, "</p><p class=\"quickie-paragraph\">")
        processed_title.gsub!("\n", "<br>")
        if processed_title.include?("<br>") || processed_title.include?("</p><p")
          processed_title = "<p class=\"quickie-paragraph\">#{processed_title}</p>"
          processed_title.gsub!("<p class=\"quickie-paragraph\"></p>", "")
          processed_title.gsub!(%r{<p class="quickie-paragraph">\s*</p>}, "")
          processed_title.gsub!(/<p class="quickie-paragraph">\s+/, "<p class=\"quickie-paragraph\">")
          processed_title.gsub!(%r{\s+</p>}, "</p>")
        end
        processed_title += '<span class="quickie-read-more">...read more</span>' if truncate_for_feed
        processed_title.gsub(%r{https?://[^\s<>"{}|\\^`\[\]]+}) do |url|
          clean_url = url.gsub(%r{^https?://}, "").gsub(/^www\./, "").chomp("/")
          display_url = clean_url.length > 25 ? "#{clean_url[0..21]}..." : clean_url
          "<span style=\"text-decoration: underline;\">#{display_url}</span>"
        end
      end
    end

    let(:edge_cases) do
      [
        "", "Hello world", "a\nb", "a\n\nb", "a\n \t\n \n b", "a\r\nb", "a\r\n\r\nb", "\n\n", "\n\nhi\n\n", "  \n  ",
        "a\n \nb", "a\n \n\u0085b", "a\v\n\f\nb", "x<br>y", "x </p>", "x </p><p y",
        "<p class=\"quickie-paragraph\"></p>\nx", "<p class=\"quickie-paragraph\">  </p></p>\n",
        "see https://www.example.com/ now", "http://abcdefghijklmnopqrstuvwxyz.com", "http:// x", "httpx://y",
        "hhttps://a", "http:///", "https://www.", "https://a.dev\nnext", "https://a.dev/x?q=1&b=2#f\"quoted\"",
        "https://例え.テスト/日本語のパスはとても長いのでここで切り詰められます", "🎉 launch day!\n\nhttps://dev.to/🎉",
        "1\n2\n3\n4\n5\n6\n7\n8\n9", "a\n\n\n\n\n\n\n\n\n", "\n\n\n\n\n\n\n\n", "\n\na\n\nb\n\nc\n\nd\n\ne\n\nf\n\ng"
      ]
    end

    it "matches the legacy title_finalized and truncate_title_for_feed pipelines across edge cases" do
      edge_cases.product([false, true]) do |title, truncate_for_feed|
        actual = described_class.quickie_title_html(title, truncate_for_feed: truncate_for_feed)
        expect(actual).to eq(legacy_quickie_title_html.call(title, truncate_for_feed)),
                          [title, truncate_for_feed].inspect
        expect(actual.encoding).to eq(Encoding::UTF_8)
      end
    end

    it "declines titles that are not valid UTF-8 Strings" do
      ["x\n\xC3\xA9".b, "\xFF\nhttp://a", "a\nb".encode("UTF-16LE"), ActiveSupport::SafeBuffer.new("a\nb"), nil,
       :title].each do |title|
        expect(described_class.quickie_title_html(title)).to be_nil, title.inspect
      end
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      pieces = ["\n", "\n", "\r\n", " ", "\t", "\v", "\f", "\r", " ", " ", "a", "word", "日本", "🎉", "é",
                "http", "https://", "http://", "www.", "/", "<br>", "</p>", "<p", "</p><p",
                "<p class=\"quickie-paragraph\">", "<p class=\"quickie-paragraph\"></p>", "example.com",
                "abcdefghijklmnopqrstuvwxyz", "\"", "<", ">", "[", "]", "{", "|", "\\", "^", "`", "?q=1&b=2", "#f",
                "s", ":", "hhttp"]

      truncate_modes = [false, true].freeze

      1_000.times do
        title = Array.new(rng.rand(1..30)) { pieces.sample(random: rng) }.join
        truncate_modes.each do |truncate_for_feed|
          expect(described_class.quickie_title_html(title, truncate_for_feed: truncate_for_feed))
            .to eq(legacy_quickie_title_html.call(title, truncate_for_feed)), [title, truncate_for_feed].inspect
        end
      end
    end
  end

  describe ".host_without_www" do
    let(:legacy_host_without_www) do
      lambda do |url|
        url = url.strip
        url = "http://#{url}" if Addressable::URI.parse(url).scheme.nil?
        Addressable::URI.parse(url).host.downcase.delete_prefix("www.")
      end
    end
    let(:helper_host) { Object.new.extend(ArticlesHelper) }

    it "matches the Addressable host extraction across edge cases" do
      [
        "https://www.example.com", "https://www.EXAMPLE.COM", "https://www.medium.com", "https://premedium.com",
        "www.example.com", " www.example.com ", "\0\t\vwww.a.com/x \r\n\0", "http://a.com:/x", "https://a.com#frag",
        "a.com?q=1:2", "a.com/b:c", "HTTPS://WwW.medium.com/@user/post", "https://a.com:080", "https://www.www.a.com",
        "git+ssh://Host.example.org/repo", "https://dev.to/ben/my-post-1abc?utm_source=x#comment"
      ].each do |url|
        actual = described_class.host_without_www(url)
        expect(actual).to eq(legacy_host_without_www.call(url)), url.inspect
        expect(actual.encoding).to eq(Encoding::UTF_8)
      end
    end

    it "declines URLs that need Addressable and keeps the helper's legacy result" do
      [
        "", "a.com:8080", "http:a.com", "1http://a.com", "http://", "/path", "::1", "//a.com:x", "https://user@a.com",
        "https://[::1]/x", "https://a.com:1a", "https://a.com:%31", "https://a<b.com", "https://exämple.com",
        "https://ÉXAMPLE.com", "https://a.com/\u{1f600}", " https://a.com/x".encode("UTF-16LE"),
        "https://a.com/\xFF", ActiveSupport::SafeBuffer.new("https://a.com"), nil
      ].each do |url|
        expect(described_class.host_without_www(url)).to be_nil, url.inspect
      end
      expect(helper_host.get_host_without_www("https://user@WWW.Medium.com")).to eq("Medium")
      expect(helper_host.get_host_without_www(" https://www.Éxample.com ")).to eq("éxample.com")
      expect { helper_host.get_host_without_www("a.com:8080") }.to raise_error(NoMethodError)
      expect { helper_host.get_host_without_www("1http://a.com") }.to raise_error(Addressable::URI::InvalidURIError)
    end

    it "passes differential equivalence across 1,000 accepted generated inputs" do
      rng = Random.new(424_242)
      tokens = ["http", "https", "HTTP", "git+ssh", "1x", "www.", "WWW.", "Example", "dev.to", "medium.com", "a", "b-c",
                "_", "%41", ":", "//", "/", "?", "#", "@", "[", "]", "::1", "80", "x", "<", ">", "{", "\"", "\\", "|",
                "`", " ", "\t", "\n", "\0", "é", "\u{1f600}", ".", "+", "-", "=", "&", ";", "~", "!", "(", ","]
      accepted = 0

      20_000.times do |iteration|
        url = Array.new(rng.rand(1..12)) { tokens.sample(random: rng) }.join
        actual = described_class.host_without_www(url)
        next if actual.nil?

        accepted += 1
        expected = legacy_host_without_www.call(url)
        expect(actual).to eq(expected), "iteration #{iteration}: #{url.inspect}"
        expect(helper_host.get_host_without_www(url)).to eq(expected == "medium.com" ? "Medium" : expected)
        break if accepted == 1_000
      end
      expect(accepted).to eq(1_000)
    end
  end

  describe ".content_includes_title" do
    let(:legacy_content_includes_title) do
      ->(content, title) { content.gsub(/[[:space:]]/, " ").include?(title.delete("…")) }
    end
    let(:feed_item_class) do
      Class.new do
        attr_reader :url, :title, :content

        def initialize(url:, title:, content:, categories: nil)
          @url = url
          @title = title
          @content = content
          @categories = categories
        end

        def [](field)
          instance_variable_get(:"@#{field}")
        end
      end
    end
    let(:medium_reply?) do
      lambda do |content, title, categories: nil|
        item = feed_item_class.new(url: " https://Medium.com/@user/reply-1 ", title: title, content: content,
                                   categories: categories)
        Feeds::CheckItemMediumReply.call(item)
      end
    end

    it "matches the whitespace-normalized include? check across edge cases" do
      [
        ["", ""], ["anything", ""], ["", "a"], ["anything", "……"], ["<p>Hello world</p>", "Hello world"],
        ["<p>Hello world</p>", "Goodbye"], ["I think this is right", "I think…"], ["abc", "a…b…c"],
        ["I think…", "I think… really"], ["I think…", "I think"], ["Hello\nworld", "Hello world"],
        ["Hello\r\nworld", "Hello world"], ["Hello\r\nworld", "Hello  world"], ["Hello\u00A0world", "Hello world"],
        ["a\u2028b\u0085c\u3000d\u1680e\u202Ff\u205Fg", "a b c d e f g"], ["Hello\nworld", "Hello\nworld"],
        ["Hello\u00A0world", "Hello\u00A0world"], ["tab\there", "\t"], ["a\u200Bb", "a b"], ["a\u200Bb", "a\u200Bb"],
        ["a\u180Eb", "a b"], ["日本語\nのタイトル 🎉", "日本語 のタイトル 🎉"], ["日本語のタイトル", "タイトル🎉"]
      ].each do |content, title|
        expected = legacy_content_includes_title.call(content, title)
        expect(described_class.content_includes_title(content, title)).to be(expected), [content, title].inspect
        expect(medium_reply?.call(content, title)).to be(expected)
      end
      expect(medium_reply?.call("Hello world", "Hello world", categories: ["dev"])).to be(false)
    end

    it "declines non-UTF-8 and invalid strings and keeps the service's legacy result" do
      [
        [nil, "a"], ["a", nil], ["a\xFFb", "a"], ["a", "\xFF"], ["ab".encode("UTF-16LE"), "a"], ["ab".b, "a"],
        ["ab", "a".encode("US-ASCII")], [ActiveSupport::SafeBuffer.new("ab"), "a"], [:ab, "a"]
      ].each do |content, title|
        expect(described_class.content_includes_title(content, title)).to be_nil, [content, title].inspect
      end
      expect(medium_reply?.call("Hello\nworld", "Hello world".encode("US-ASCII"))).to be(true)
      expect(medium_reply?.call("ab".b, "a".b)).to be(true)
      expect { medium_reply?.call(nil, "a") }.to raise_error(NoMethodError)
      expect { medium_reply?.call("a\xFFb", "a") }.to raise_error(ArgumentError)
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = ["a", "b", "Hello", "world", " ", "  ", "\n", "\r\n", "\t", "\v", "\f", "\u0085", "\u00A0", "\u1680",
                "\u2000", "\u200A", "\u200B", "\u2028", "\u202F", "\u205F", "\u3000", "…", "...", "<p>", "</p>",
                "é", "日本", "\u{1F600}", "-", "."]
      positives = 0

      1_000.times do |iteration|
        content = Array.new(rng.rand(1..16)) { tokens.sample(random: rng) }.join
        title = if rng.rand < 0.5
                  start = rng.rand(content.length)
                  content[start, rng.rand(1..8)].gsub(/[[:space:]]/) { rng.rand < 0.8 ? " " : _1 }
                else
                  Array.new(rng.rand(1..4)) { tokens.sample(random: rng) }.join
                end
        title = title.chars.flat_map { |char| rng.rand < 0.1 ? [char, "…"] : [char] }.join

        expected = legacy_content_includes_title.call(content, title)
        positives += 1 if expected
        message = "iteration #{iteration}: #{[content, title].inspect}"
        expect(described_class.content_includes_title(content, title)).to be(expected), message
        expect(medium_reply?.call(content, title)).to be(expected)
      end
      expect(positives).to be_between(200, 800)
    end
  end

  describe ".subforem_request_domain" do
    let(:legacy_subforem_request_domain) do
      lambda do |raw_domain|
        parsed_host = begin
          URI.parse(raw_domain).host
        rescue StandardError
          nil
        end
        parsed_host.presence ||
          raw_domain.gsub(%r{\Ahttps?://}, "").split("/").first&.split(":")&.first.presence || raw_domain
      end
    end
    let(:middleware) { Middlewares::SetSubforem.new(->(_env) { [200, {}, []] }) }

    it "matches the URI.parse domain extraction across edge cases" do
      [
        "dev.to", "DEV.to", "community.example.com", "localhost", "localhost:3000", "dev.to:443", "dev.to:",
        "127.0.0.1:3000", "1a:2", "a-b.c-d:0", ".:1", "...", "-", "dev.to".b, "dev.to:3000".b,
        "dev.to".encode("US-ASCII")
      ].each do |raw|
        actual = described_class.subforem_request_domain(raw)
        expect(actual).to eq(legacy_subforem_request_domain.call(raw)), raw.inspect
        expect(actual.encoding).to eq(raw.encoding)
      end
      host = +"dev.to"
      expect(described_class.subforem_request_domain(host)).to equal(host)
    end

    it "declines domains that need URI.parse and keeps the middleware's legacy result" do
      [
        "", " ", ":3000", "https://dev.to", "http://dev.to:3000/x", "dev.to/path", "dev.to:443:1", "dev.to:x",
        " dev.to", "dev_to", "user@example.com", "[::1]:3000", "dév.to", "dev.to\n", "dev.to".encode("UTF-16LE"),
        ActiveSupport::SafeBuffer.new("dev.to"), nil, ["dev.to"]
      ].each do |raw|
        expect(described_class.subforem_request_domain(raw)).to be_nil, raw.inspect
      end
      expect(middleware.__send__(:legacy_request_domain, "https://Override.example.com/x"))
        .to eq("Override.example.com")
      expect(middleware.__send__(:legacy_request_domain, ":3000")).to eq(":3000")
      expect(middleware.__send__(:legacy_request_domain, "http:/a.com")).to eq("http")
    end

    it "passes differential equivalence across 1,000 accepted generated inputs" do
      rng = Random.new(424_242)
      tokens = ["dev", "to", "DEV", "example", "com", "localhost", "a", "b-c", "1", "443", "3000", ".", ".", "-", ":",
                ":", "//", "/", "http", "https", "@", "_", "[", "]", " ", "\n", "é", "%41", "?", "#", "+"]
      accepted = 0

      20_000.times do |iteration|
        raw = Array.new(rng.rand(1..6)) { tokens.sample(random: rng) }.join
        actual = described_class.subforem_request_domain(raw)
        next if actual.nil?

        accepted += 1
        expected = legacy_subforem_request_domain.call(raw)
        expect(actual).to eq(expected), "iteration #{iteration}: #{raw.inspect}"
        expect(middleware.__send__(:legacy_request_domain, raw)).to eq(expected)
        break if accepted == 1_000
      end
      expect(accepted).to eq(1_000)
    end
  end

  describe ".subforem_subdomain_host" do
    let(:legacy_subforem_subdomain_host) do
      ->(host, sld, tld) { !(host =~ /^([^.]+)\.#{sld}\.#{tld}$/).nil? }
    end

    it "matches the interpolated Regexp across edge cases" do
      [
        ["dev.to", "dev", "to"], ["www.dev.to", "dev", "to"], ["a.b.dev.to", "dev", "to"], ["xdev.to", "dev", "to"],
        ["a.dev.to", "dev", "to"], ["a.DEV.to", "dev", "to"], ["a.bbc.co.uk", "bbc", "co.uk"],
        ["a.bbc.coxuk", "bbc", "co.uk"], ["a.bbc.co-uk", "bbc", "co.uk"], [".dev.to", "dev", "to"],
        ["a.dev.to.", "dev", "to"], ["a.devxto", "dev", "to"], ["a-b.my-site.io", "my-site", "io"],
        ["", "dev", "to"], ["community.example.com".b, "example", "com"]
      ].each do |host, sld, tld|
        expect(described_class.subforem_subdomain_host(host, sld, tld))
          .to eq(legacy_subforem_subdomain_host.call(host, sld, tld)), [host, sld, tld].inspect
      end
    end

    it "declines hosts and labels that need the Regexp" do
      [
        ["a.dev.to", "", "to"], ["a.dev.to", "dev", ""], ["a.dev.to", "d.v", "to"], ["a.dev.to", "de*", "to"],
        ["a.dev.to", "dev", "t+"], ["a.dev.to\n", "dev", "to"], ["a b.dev.to", "dev", "to"],
        ["a_b.dev.to", "dev", "to"], ["ä.dev.to", "dev", "to"], ["a.dev.to".encode("UTF-16LE"), "dev", "to"],
        [nil, "dev", "to"], ["a.dev.to", nil, "to"], ["a.dev.to", "dev", :to]
      ].each do |host, sld, tld|
        expect(described_class.subforem_subdomain_host(host, sld, tld)).to be_nil, [host, sld, tld].inspect
      end
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      labels = %w[dev to co uk bbc example com a b x my-site io DEV 1 -]
      positives = 0

      1_000.times do |iteration|
        sld = labels.sample(random: rng)
        tld = Array.new(rng.rand(1..2)) { labels.sample(random: rng) }.join(".")
        host = Array.new(rng.rand(1..5)) { (labels + [sld, tld, "", "x"]).sample(random: rng) }.join(".")
        host = [host, "#{labels.sample(random: rng)}.#{sld}.#{tld}"].sample(random: rng)
        actual = described_class.subforem_subdomain_host(host, sld, tld)
        expect(actual).to eq(legacy_subforem_subdomain_host.call(host, sld, tld)),
                          "iteration #{iteration}: #{[host, sld, tld].inspect}"
        positives += 1 if actual
      end
      expect(positives).to be_between(200, 800)
    end
  end

  describe ".original_host_valid" do
    let(:legacy_original_host_valid) do
      lambda do |host|
        host_without_port = host.split(":").first
        host_without_port.match?(Middlewares::RestoreOriginalHost::VALID_HOST_REGEXP) ||
          host_without_port == "localhost"
      end
    end
    let(:middleware) { Middlewares::RestoreOriginalHost.new(->(env) { [200, env, []] }) }

    it "matches the host Regexp across edge cases" do
      [
        "mlh.forem.wtf", "sub-domain.example.com", "localhost", "localhost:3000", "DEV.TO", "dev.to:443", "a.bc",
        "1.2.3.ab", "a.cd:x:y", "a.cd:", "a.b", "a.b2", "a.b-cd", "a..cd", "-a.cd", "a-.cd", "a.cd.", ".a.cd",
        "a.c1d", "1.2.3.4", "xn--d1a.com", "LOCALHOST", "localhost.:", "a--b.cd", "ab", "invalid host",
        "host\nname", "host;name", "http://host.com", "dev.to".b, "dev.to".encode("US-ASCII")
      ].each do |host|
        expect(described_class.original_host_valid(host)).to eq(legacy_original_host_valid.call(host)), host.inspect
      end
    end

    it "declines hosts that need the legacy check and keeps the middleware's legacy result" do
      ["", ":", ":::", ":3000", "\u212Aa.com", "a.co\u017F", "dév.to", "a.com:\xFF", "\xFF.com".b,
       "dev.to".encode("UTF-16LE"), nil, :host].each do |host|
        expect(described_class.original_host_valid(host)).to be_nil, host.inspect
      end
      expect(middleware.__send__(:valid_host?, "\u212Aa.com")).to be(true)
      expect(middleware.__send__(:valid_host?, "dév.to")).to be(false)
      expect(middleware.__send__(:valid_host?, ":3000")).to be(false)
      expect { middleware.__send__(:valid_host?, ":::") }.to raise_error(NoMethodError)
      expect { middleware.__send__(:valid_host?, "a.com:\xFF") }.to raise_error(ArgumentError)
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = ["dev", "to", "DEV", "forem", "com", "a", "b2", "1", "localhost", "xn", "wtf", ".", ".", ".", "-", "-",
                ":", "443", " ", "_", "/", ";", "\n", "é"]
      positives = 0

      1_000.times do |iteration|
        host = if rng.rand < 0.3
                 Array.new(rng.rand(1..3)) { %w[dev forem mlh sub-domain a1 DEV].sample(random: rng) }.join(".")
               else
                 Array.new(rng.rand(1..7)) { tokens.sample(random: rng) }.join
               end
        host = "#{host}.#{%w[to com wtf].sample(random: rng)}" if rng.rand < 0.4
        host = "#{host}:#{rng.rand(1..65_535)}" if rng.rand < 0.2
        actual = described_class.original_host_valid(host)
        expected = begin
          legacy_original_host_valid.call(host)
        rescue NoMethodError, ArgumentError
          nil
        end
        message = "iteration #{iteration}: #{host.inspect}"
        if actual.nil?
          expect(host.ascii_only? && !host.start_with?(":")).to be(false), message
        else
          expect(actual).to eq(expected), message
          positives += 1 if actual
        end
        env = { "HTTP_HOST" => "practicaldev.herokuapp.com", "HTTP_FASTLY_ORIG_HOST" => host }
        if expected.nil?
          expect { middleware.call(env) }.to raise_error(NoMethodError), message
        else
          expect(middleware.call(env)[1]["HTTP_HOST"]).to eq(expected ? host : "practicaldev.herokuapp.com"), message
        end
      end
      expect(positives).to be_between(200, 800)
    end
  end

  describe ".inline_svg_icon (CrayonsHelper#crayons_icon_tag)" do
    let(:view) do
      Class.new do
        include InlineSvg::ActionView::Helpers
        include CrayonsHelper
      end.new
    end
    let(:icon_names) do
      root = Rails.root.join("app/assets/images")
      Dir.glob(root.join("**/*.svg")).map { |path| path.delete_prefix("#{root}/").delete_suffix(".svg") }.sort
    end
    # The pre-ForemNative body of CrayonsHelper#crayons_icon_tag.
    let(:legacy_crayons_icon_tag) do
      lambda do |name, native: false, **opts|
        name = name.to_s
        icon_name = name.ends_with?(".svg") ? name : "#{name}.svg"
        icon_class = ["crayons-icon", ("crayons-icon--default" if native), opts.delete(:class)].compact.join(" ")
        opts[:width] ||= 24
        opts[:height] ||= 24
        view.inline_svg_tag(icon_name, aria: true, class: icon_class, **opts)
      end
    end

    # Title ids are random; make both renderers draw the same ids.
    def with_fixed_title_ids
      allow(InlineSvg::IdGenerator::Randomness).to receive(:call).and_return("fixed")
      yield
    end

    it "matches inline_svg_tag for common icon options" do
      with_fixed_title_ids do
        [
          ["small-medal", {}], ["x", { class: "pointer-events-none" }], ["twemoji/flag", { native: true }],
          ["small-overflow-horizontal", { class: "pointer-events-none", title: "Menu" }],
          [:search, { aria_hidden: true }], ["chevron-down", { width: 16, height: "16" }],
          ["checkmark", { title: "Tom & \"Jerry\" <3 😀", class: "a & b" }], ["lock", { title: "" }],
          ["external-link", { aria_hidden: false, title: nil }], ["copy", { aria_hidden: "false" }]
        ].each do |name, opts|
          expected = legacy_crayons_icon_tag.call(name, **opts.dup)
          actual = view.crayons_icon_tag(name, **opts.dup)
          expect(actual).to eq(expected), [name, opts].inspect
          expect(actual).to be_html_safe
        end
      end
    end

    it "declines what needs Nokogiri and keeps the helper's legacy result" do
      svg = "<svg viewBox=\"0 0 1 1\"></svg>\n"
      expect(described_class.inline_svg_icon(svg, "c", "24", "24")).to eq(
        "<svg viewBox=\"0 0 1 1\" role=\"img\" class=\"c\" width=\"24\" height=\"24\"></svg>\n",
      )
      expect(described_class.inline_svg_icon("<svg><title>t</title></svg>\n", "c", "24", "24")).to be_nil
      [["c\"", "24", "24"], ["c\n", "24", "24"], ["c", 24, "24"], [nil, "24", "24"], ["c", "24", "\xFF"],
       ["c", "24", "\xFF".b], ["c", "24", "24".encode("UTF-16LE")]].each do |args|
        expect(described_class.inline_svg_icon(svg, *args)).to be_nil, args.inspect
      end
      expect(described_class.inline_svg_icon(svg, "c", "24", "24", title: "t")).to be_nil
      expect(described_class.inline_svg_icon(svg, "c", "24", "24", aria_hidden: true)).to be_nil
      with_fixed_title_ids do
        [
          ["x", { title: "a\rb" }], ["x", { style: "color: red" }], ["x", { width: 1.5 }], ["x", { aria_hidden: :yes }],
          ["x", { data: { a: 1 } }], ["no-such-icon", {}], ["x", { class: "a\"b" }]
        ].each do |name, opts|
          expect(view.crayons_icon_tag(name, **opts.dup)).to eq(legacy_crayons_icon_tag.call(name, **opts.dup))
        end
      end
      allow(InlineSvg.configuration).to receive(:custom_transformations).and_return(no_attribute: {})
      expect(view.__send__(:native_crayons_icon_tag, "x.svg", "c", { width: 24, height: 24 })).to be_nil
    end

    it "passes differential equivalence across every icon and 1,000 generated option sets" do
      rng = Random.new(424_242)
      pieces = ["crayons-icon", "pointer-events-none", " ", "  ", "a", "Zz", "&", "&amp;", "<", ">", "\"", "'", "é",
                "中", "😀", "\u00A0", "\u2028", "\t", "\n", "\r", "\u0001", "\u007F", "\u0085", "\uFFFE", "16", "24"]
      word = -> { Array.new(rng.rand(1..4)) { pieces.sample(random: rng) }.join }
      native_hits = 0

      with_fixed_title_ids do
        icon_names.each do |name|
          expect(view.crayons_icon_tag(name)).to eq(legacy_crayons_icon_tag.call(name)), name
          expect(view.crayons_icon_tag(name, title: name)).to eq(legacy_crayons_icon_tag.call(name, title: name)), name
        end

        1_000.times do |iteration|
          name = icon_names.sample(random: rng)
          opts = {}
          opts[:native] = true if rng.rand < 0.2
          opts[:class] = word.call if rng.rand < 0.6
          opts[:title] = word.call if rng.rand < 0.5
          opts[:aria_hidden] = [true, false, "true", word.call].sample(random: rng) if rng.rand < 0.3
          opts[:width] = [16, 24, "16", word.call].sample(random: rng) if rng.rand < 0.3
          opts[:height] = [16, 24, "16", word.call].sample(random: rng) if rng.rand < 0.3
          native_opts = { width: 24, height: 24 }.merge(opts.except(:native, :class).compact_blank)
          native_hits += 1 if view.__send__(:native_crayons_icon_tag, "#{name}.svg", "c", native_opts)
          expect(view.crayons_icon_tag(name, **opts.dup)).to eq(legacy_crayons_icon_tag.call(name, **opts.dup)),
                                                             "iteration #{iteration}: #{[name, opts].inspect}"
        end
      end
      expect(native_hits).to be > 500
    end
  end

  describe ".public_suffix_domain" do
    let(:legacy_public_suffix_domain) do
      lambda do |host|
        PublicSuffix.parse(host, default_rule: nil).domain
      rescue PublicSuffix::DomainInvalid
        false
      end
    end
    let(:cookie_middleware) { Middlewares::SetCookieDomain.new(->(env) { [200, env, []] }) }

    it "matches PublicSuffix.parse(host, default_rule: nil).domain across normal, wildcard, and exception rules" do
      [
        "dev.to", "DEV.TO", "community.example.com", "a.b.example.co.uk", "  EXAMPLE.COM. \t\r\n",
        "bar.foo.ck", "www.ck", "sub.www.ck", "city.kawasaki.jp", "www.city.kawasaki.jp",
        "bar.foo.kawasaki.jp", "my-app.s3.amazonaws.com", "foo_bar.example.com", "example.com".b,
        "sub.example.com".b, "example.com".encode("US-ASCII"), nil, "", "   ", ".", ".example.com",
        "example.com..", "..com", "com", "co.uk", "ck", "foo.ck", "kawasaki.jp", "foo.kawasaki.jp",
        "localhost", "127.0.0.1", "example.invalidtld", "example.com:3000", "http://example.com"
      ].each do |host|
        expected = legacy_public_suffix_domain.call(host)
        actual = described_class.public_suffix_domain(host)
        expect(actual).to eq(expected), host.inspect
        expect(actual.encoding).to eq(host.encoding) if actual.is_a?(String)
        expect(cookie_middleware.root_domain(host)).to eq(expected || host), host.inspect
      end

      host = +"dev.to"
      expect(described_class.public_suffix_domain(host)).to equal(host)
    end

    it "declines non-ASCII, NUL, embedded newlines, and consecutive dots so callers fall back to PublicSuffix" do
      [
        "dév.to", "example.公司.cn", "example..com", "foo\nbar.com", "example.com\0",
        "dev.to".encode("UTF-16LE"), ActiveSupport::SafeBuffer.new("dev.to"), :dev_to
      ].each do |host|
        expect(described_class.public_suffix_domain(host)).to be_nil, host.inspect
      end
      expect(cookie_middleware.root_domain("sub.example.公司.cn")).to eq("example.公司.cn")
      expect(cookie_middleware.root_domain("example..com")).to eq("example.com")
    end

    it "passes differential equivalence across 1,000 accepted generated inputs" do
      rng = Random.new(424_242)
      labels = %w[dev to DEV example com co uk ck www city kawasaki jp amazonaws s3 sub my-site io localhost 127 0 1
                  invalidtld]
      tlds = %w[to com io dev co.uk ck www.ck kawasaki.jp city.kawasaki.jp s3.amazonaws.com invalidtld]
      tokens = labels + [".", ".", "-", "_", ":", "3000", "://", "http", " ", "\t", "\r", "\v", "\f"]
      accepted = 0
      valid_count = 0

      20_000.times do |iteration|
        sample = if rng.rand < 0.5
                   "#{Array.new(rng.rand(1..3)) { labels.sample(random: rng) }.join('.')}.#{tlds.sample(random: rng)}"
                 else
                   Array.new(rng.rand(1..6)) { tokens.sample(random: rng) }.join
                 end
        actual = described_class.public_suffix_domain(sample)
        next if actual.nil?

        accepted += 1
        expected = legacy_public_suffix_domain.call(sample)
        valid_count += 1 if expected
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(actual).to eq(expected), message
        expect(cookie_middleware.root_domain(sample)).to eq(expected || sample), message
        break if accepted == 1_000
      end
      expect(accepted).to eq(1_000)
      expect(valid_count).to be_between(200, 800)
    end
  end

  describe ".public_suffix_subdomain_host" do
    let(:legacy_public_suffix_subdomain_host) do
      lambda do |host|
        parsed = PublicSuffix.parse(host, default_rule: nil)
        !(host =~ /^([^.]+)\.#{parsed.sld}\.#{parsed.tld}$/).nil?
      rescue PublicSuffix::DomainInvalid
        :invalid
      end
    end

    it "matches the PublicSuffix.parse + subdomain Regexp pipeline in Middlewares::SetSubforem" do
      [
        "community.example.com", "example.com", "a.b.example.com", "SUB.example.com",
        "sub.EXAMPLE.com", "COMMUNITY.EXAMPLE.COM", "sub.example.com.", "sub.bbc.co.uk",
        "bbc.co.uk", "a.b.bbc.co.uk", "sub.www.ck", "www.ck", "sub.foo.ck", "bar.sub.foo.ck",
        "foo.ck", "ck", "com", "localhost", "127.0.0.1", "example.invalidtld", "example.com:3000",
        "http://example.com", "", ".", ".example.com", nil, "community.example.com".b,
        "community.example.com".encode("US-ASCII")
      ].each do |host|
        expect(described_class.public_suffix_subdomain_host(host))
          .to eq(legacy_public_suffix_subdomain_host.call(host)), host.inspect
      end
    end

    it "declines hosts outside [A-Za-z0-9.-] or non-ASCII so SetSubforem can fall back" do
      [
        "foo_bar.example.com", "  sub.example.com  ", "dév.to", "sub.example.公司.cn",
        "sub..example.com", "sub.example.com\n", "sub.example.com".encode("UTF-16LE"),
        ActiveSupport::SafeBuffer.new("sub.example.com"), :host
      ].each do |host|
        expect(described_class.public_suffix_subdomain_host(host)).to be_nil, host.inspect
      end
    end

    it "passes differential equivalence across 1,000 accepted generated inputs" do
      rng = Random.new(424_242)
      labels = %w[dev to bbc example com a b sub my-site io DEV 1 - localhost invalid]
      tlds = %w[to com io co.uk ck www.ck kawasaki.jp city.kawasaki.jp invalid]
      accepted = 0
      subdomains = 0

      20_000.times do |iteration|
        host = if rng.rand < 0.5
                 "#{labels.sample(random: rng)}.#{labels.sample(random: rng)}.#{tlds.sample(random: rng)}"
               else
                 Array.new(rng.rand(1..5)) { labels.sample(random: rng) }.join(".")
               end
        actual = described_class.public_suffix_subdomain_host(host)
        next if actual.nil?

        accepted += 1
        expected = legacy_public_suffix_subdomain_host.call(host)
        subdomains += 1 if expected == true
        expect(actual).to eq(expected), "iteration #{iteration}: #{host.inspect}"
        break if accepted == 1_000
      end
      expect(accepted).to eq(1_000)
      expect(subdomains).to be_between(200, 800)
    end
  end

  describe ".full_sanitize (ActionView::Base.full_sanitizer.sanitize)" do
    let(:legacy_sanitize) { ->(html) { ActionView::Base.full_sanitizer.sanitize(html) } }

    let(:edge_cases) do
      [
        "",
        "plain text without markup",
        "日本語 🎉 café naïve 👨‍👩‍👧‍👦 e\u0301",
        "<p>Hello <b>world</b>!</p>",
        "<div class=\"a\" data-x=\"1 > 2\" data-y='3 < 4' disabled>text</div>",
        "<a href=https://dev.to/ben/post?a=1&amp;b=2 target=_blank rel=noopener>link</a>",
        "<!DOCTYPE html><!-- comment --><!----><p>doc</p>",
        "Tom & Jerry &amp; &lt; &gt; &quot; &#39; &#x27; &apos; &nbsp; &#160; &#xA0;",
        "&#x25B8; &middot; &copy; &reg; &trade; &mdash; &ndash; &hellip; &lsquo; &rsquo; &ldquo; &rdquo; &rarr;",
        "&euro; &bull; &larr; &uarr; &darr; &harr; &minus; &lowast; &le; &ge; &ne; &equiv; &asymp; &infin;",
        "&ensp; &emsp; &thinsp; &zwnj; &zwj; &lrm; &rlm; &fnof; &dagger; &Dagger; &permil; &prime; &Prime; &radic;",
        "&#0; &#128; &#130; &#145; &#146; &#147; &#148; &#150; &#151; &#153; &#159;",
        "&#xD800; &#xDFFF; &#x110000; &#999999999999999; &#00038; &#128512; &#x1F600; &#X1f680; &#; &#x;",
        "a < b && c > d\u00A0e\r\nf\rg",
        "https://dev.to/search?q=rust&sort=latest&page=2",
        "<pre>\nline 1\nline 2</pre>",
        "<pre>\r\nline 1\r\nline 2</pre>",
        "<pre>\rline 1\rline 2</pre>",
        "<pre>\n\ndouble newline keeps one</pre>",
        "<pre><code>\nline 1</code></pre>",
        "<svg viewBox=\"0 0 24 24\"><title>Enter &amp; exit</title><g><path d=\"M0 0\"/></g></svg>",
        "<svg><defs><linearGradient id=\"g\"><stop offset=\"0%\"/></linearGradient></defs><circle r=\"5\"/></svg>",
        "<svg><svg viewBox=\"0 0 10 10\"><rect width=\"10\" height=\"10\"/></svg></svg>",
        "<svg/>after",
        "<table>\n<thead>\n<tr><th>H1</th><th>H2</th></tr>\n</thead>\n" \
        "<tbody>\n<tr><td>C1</td><td><b>C2</b></td></tr>\n</tbody>\n" \
        "<tfoot>\n<tr><td>F1</td><td>F2</td></tr>\n</tfoot>\n</table>",
        "<table><caption>Table <b>Caption</b></caption><colgroup><col span=\"2\"/></colgroup>" \
        "<tr><th>H</th><td><svg><path d=\"M0 0\"/></svg>Data</td></tr></table>",
        "<style>.a > .b { content: \"<x>\"; }</style>",
        "<script>const a = 1 < 2 && 3 > 1;</script>",
        "<iframe src=\"https://youtube.com/embed/1\">fallback <b>text</b></iframe>",
        "<textarea>\n<b>raw</b> &amp; text</textarea>",
        "<textarea>\r\n<b>raw</b> &lt;text&gt;</textarea>",
        "<title>Title &amp; Text</title>",
      ]
    end

    it "matches ActionView::Base.full_sanitizer.sanitize across edge cases and editor guide HTML" do
      edge_cases.each do |html|
        expected = legacy_sanitize.call(html)
        expect(described_class.full_sanitize(html)).to eq(expected), html.inspect
      end

      raw_guide = Rails.root.join("app/views/pages/_editor_guide_text.en.html.erb").read
      guide_without_erb = raw_guide.gsub(/<%=.*?%>/, "").gsub(/<%.*?%>/, "")
      expect(described_class.full_sanitize(guide_without_erb)).to eq(legacy_sanitize.call(guide_without_erb))
    end

    it "declines malformed table markup, implicit cell closures, scoping elements, and SVG breakouts" do
      malformed_and_quirky_cases = [
        # P2 regression: implicit cell closure on </tr> followed by foster-parented stray text
        "<table><tr><td>A</tr> stray</td></table>",
        "<table><tr><th>A</tr> stray</th></table>",
        # Other end tags that implicitly close an open <td> or <th> in HTML5 "in cell" mode
        "<table><tr><td>A</tbody> stray</td></table>",
        "<table><thead><tr><td>A</thead> stray</td></tr></table>",
        "<table><tfoot><tr><td>A</tfoot> stray</td></tr></table>",
        "<table><tr><td>A</table> stray</td>",
        "<table><tr><td>A</th> stray</td></tr></table>",
        "<table><tr><th>A</td> stray</th></tr></table>",
        # Start tags inside <td>/<th> that implicitly close the cell in HTML5 "in cell" mode
        "<table><tr><td>A<tr> stray</td></tr></table>",
        "<table><tr><td>A<td>B</td> stray</tr></table>",
        "<table><tr><td>A<th>B</th> stray</tr></table>",
        "<table><tr><td>A<tbody><tr><td>B</td></tr></tbody> stray</tr></table>",
        "<table><tr><td>A<thead><tr><td>B</td></tr></thead> stray</tr></table>",
        "<table><tr><td>A<tfoot><tr><td>B</td></tr></tfoot> stray</tr></table>",
        "<table><tr><td>A<caption>B</caption> stray</tr></table>",
        "<table><tr><td>A<colgroup><col></colgroup> stray</tr></table>",
        "<table><tr><td>A<col> stray</td></tr></table>",
        "<table><tr><td><table><tr><td>nested</td></tr></table></td></tr></table>",
        # Mismatched section/caption/colgroup/row transitions and foster-parented text/elements
        "<table><thead><tr><td>A</tr></tbody> stray</thead></table>",
        "<table><tbody><tr><td>A</td></tr></thead>stray</table>",
        "<table><caption>A<tr><td>B</td></tr>stray</caption></table>",
        "<table><caption>A</table>stray",
        "<table><colgroup>stray</colgroup><tr><td>A</td></tr></table>",
        "<table><colgroup><span>A</span></colgroup><tr><td>B</td></tr></table>",
        "<table><col><tr><td>A</td></tr></table>",
        "<table><tr><td>1</td></tr>stray<td>2</td></table>",
        "<table><b>stray</b><tr><td>1</td></tr></table>",
        "<table><tr><span>stray</span><td>1</td></tr></table>",
        "<table><tr>stray<td>1</td></tr></table>",
        # Unclosed, orphan, or self-closing table elements
        "<table><tr><td>unclosed",
        "<table><tr><td>A</td>",
        "<table><tr><td>A</td></tr>",
        "</td><td>orphan</td>",
        "</tr><tr><td>orphan</td></tr>",
        "</table>",
        "<table/><tr><td>A</td></tr>",
        "<table><tr/><td>A</td></table>",
        "<table><tr><td/>A</tr></table>",
        "<table><tr><th/>A</tr></table>",
        # HTML5 scoping elements inside <td> that prevent </td> from closing the cell
        "<table><tr><td><object>A</td></tr>stray</table>",
        "<table><tr><td><marquee>A</td></tr>stray</table>",
        "<table><tr><td><applet>A</td></tr>stray</table>",
        "<table><tr><td><template>A</td></tr>stray</table>",
        # SVG foreign-content breakout tags and ancestor HTML end tags inside <svg>
        "<table><tr><td><svg>A</td></tr>stray</svg></table>",
        "<div><svg></div><p>after</p></svg>",
        "<svg><p>breakout</p></svg>",
        "<svg><div>breakout</div></svg>",
        "<svg><b>breakout</b></svg>",
        "<svg><table><tr><td>breakout</td></tr></table></svg>",
        "<svg><foreignObject><p>html</p></foreignObject></svg>",
        "<svg><desc>description</desc></svg>",
        "<svg><title><b>tag in svg title</b></title></svg>",
        "<svg/></svg>",
        "</svg>",
        "<svg><path d=\"M0 0\">",
        # Other HTML5 tokenizer / tree-builder edge cases
        "null\x00byte",
        "\uFEFFbom",
        "<!-- unclosed",
        "<!-->abrupt",
        "<!--->",
        "<?xml version=\"1.0\"?><span>pi</span>",
        "<div attr=\"unclosed>",
        "<div attr=unclosed\"quote>text</div>",
        "&CounterClockwiseContourIntegral;",
        "&copy=1",
        "&notanentity;",
        "&#123",
        "&#x1F600",
        "<pre>&#10;newline entity</pre>",
        "<textarea>&#10;newline entity</textarea>",
        "<title><b>tag in title</b></title>",
        "<script><!--</script><p>visible</p><script>--></script>",
        "<script><script></script><p>after</p>",
        "<style/>body { color: red; }",
        "<script/>alert(1)",
        "<iframe/>fallback",
        "<xmp><b>raw</b></xmp>",
        "<plaintext><b>raw</b>",
        "<noembed><b>raw</b></noembed>",
        "<noframes><b>raw</b></noframes>",
        "<noscript><b>raw</b></noscript>",
        "<select><option>opt</option><input></select>",
      ]

      # Specifically verify the P2 reviewer reproduction case foster-parents " stray" before "A"
      p2_repro = "<table><tr><td>A</tr> stray</td></table>"
      expect(described_class.full_sanitize(p2_repro)).to be_nil
      expect(legacy_sanitize.call(p2_repro)).to eq(" strayA")

      malformed_and_quirky_cases.each do |quirky|
        expect(described_class.full_sanitize(quirky)).to be_nil, quirky.inspect
        expected = legacy_sanitize.call(quirky)
        article = build(:article, processed_html: quirky)
        expect(article.body_text).to eq(expected[0..7000]), quirky.inspect
      end
    end

    it "declines non-Strings and non-UTF-8 encodings" do
      [nil, false, 123, :sym, ActiveSupport::SafeBuffer.new("<p>x</p>"), "<p>x</p>".b,
       "<p>x</p>".encode("UTF-16LE"), "<p>\xFF</p>"].each do |input|
        expect(described_class.full_sanitize(input)).to be_nil, input.inspect
      end
    end

    it "passes differential equivalence across 1,000 generated HTML fragments" do
      rng = Random.new(424_242)
      pieces = [
        "", "hello", "world", " ", "\n", "\r\n", "\r", "\t", "\u00A0", "é", "日本", "🚀",
        "&", "&amp;", "&lt;", "&gt;", "&quot;", "&apos;", "&nbsp;", "&middot;", "&copy;", "&mdash;", "&ndash;",
        "&#39;", "&#x25B8;", "&#160;", "&#0;", "&#128;", "&#146;", "&#128512;", "&#xD800;", "&#;",
        "&unknown;", "&copy=1", "&#123", "?a=1&b=2&utm_source=dev",
        "<", ">", "a < b", "x > y", "<p>", "</p>", "<br>", "<br/>", "<div class=\"a > b\" data-x='c < d'>", "</div>",
        "<a href=\"https://dev.to?a=1&amp;b=2\" target=_blank>", "</a>",
        "<a href=https://dev.to/ben/post>",
        "<!-- comment -->", "<!DOCTYPE html>",
        "<pre>\ncode</pre>", "<pre>\r\ncode</pre>", "<pre><code>\ncode</code></pre>",
        "<svg viewBox=\"0 0 24 24\"><title>Icon</title><path d=\"M0 0\"/></svg>",
        "<table>\n<thead>\n<tr><th>H</th></tr>\n</thead>\n<tbody>\n<tr><td>D</td></tr>\n</tbody>\n</table>",
        "<table><tr><td>1</td></tr>stray<td>2</td></table>",
        "<table><tr><td>A</tr> stray</td></table>",
        "<style>.a > .b { color: red; }</style>",
        "<script>const x = 1 < 2 && 3 > 1;</script>",
        "<iframe src=\"https://youtube.com/embed/1\">fallback</iframe>",
        "<textarea>\nraw <b>html</b> &amp;</textarea>",
        "<title>Title &amp; Text</title>",
        "<xmp><b>x</b></xmp>", "null\x00byte", "\uFEFFbom", "<div unclosed"
      ]
      native_hits = 0

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..10)) { pieces.sample(random: rng) }.join
        expected = legacy_sanitize.call(sample)
        native = described_class.full_sanitize(sample)
        native_hits += 1 unless native.nil?
        expect(native || expected).to eq(expected), "iteration #{iteration}: #{sample.inspect}"
      end

      expect(native_hits).to be > 500
    end

    it "passes adversarial differential equivalence across 1,000 generated table, SVG, and scoping fragments" do
      rng = Random.new(987_654)
      table_svg_tokens = [
        "<table>", "</table>", "<table/>",
        "<thead>", "</thead>", "<tbody>", "</tbody>", "<tfoot>", "</tfoot>",
        "<caption>", "</caption>", "<colgroup>", "</colgroup>", "<col>", "<col/>",
        "<tr>", "</tr>", "<tr/>", "<td>", "</td>", "<td/>", "<th>", "</th>", "<th/>",
        "<svg>", "</svg>", "<svg/>", "<path d=\"M0 0\"/>", "<g>", "</g>", "<title>", "</title>",
        "<object>", "</object>", "<marquee>", "</marquee>", "<applet>", "</applet>", "<template>", "</template>",
        "<p>", "</p>", "<div>", "</div>", "<b>", "</b>", "<br>",
        "A", "B", "stray", " ", "\n", "&amp;", "&lt;"
      ]

      1_000.times do |iteration|
        sample = if rng.rand < 0.25
                   # Mix valid table structures with random perturbations
                   "<table><thead><tr><th>#{table_svg_tokens.sample(random: rng)}</th></tr></thead>" \
                     "<tbody><tr><td>A#{table_svg_tokens.sample(random: rng)}</td>" \
                     "<td>#{table_svg_tokens.sample(random: rng)}B</td></tr></tbody></table>"
                 else
                   "<table>#{Array.new(rng.rand(2..10)) { table_svg_tokens.sample(random: rng) }.join}</table>"
                 end
        expected = legacy_sanitize.call(sample)
        native = described_class.full_sanitize(sample)
        expect(native || expected).to eq(expected), "iteration #{iteration}: #{sample.inspect}"
      end
    end
  end

  describe ".slugify_heading_anchor (AgentSessionRenderers::HeadingAnchors.slugify)" do
    let(:legacy_slugify_heading_anchor) do
      lambda do |heading_html|
        text = CGI.unescapeHTML(heading_html.to_s.gsub(/<[^>]*>/, ""))
        text.strip.downcase.gsub(AgentSessionRenderers::HeadingAnchors::SLUG_DISALLOWED, "").tr(" ", "-")
      end
    end

    it "matches HeadingAnchors.slugify across edge cases" do
      [
        "",
        "   \t\n\r\0  ",
        "!!! ???",
        "Getting Started",
        "FAQ &amp; Troubleshooting",
        "What&#39;s New in v2.0?",
        "Astro vs WordPress: the practical comparison",
        "Work through a small-business example_now",
        "Call <code>run()</code> <em>now</em>",
        "Überblick über Café",
        "İstanbul ОΣ 日本語 カタカナ 한글 🎉",
        "&<i></i>amp; &apos; &quot; &lt;b&gt; &gt; &#x41; &#X42; &#0067; &#1114111;",
        "unclosed <tag and <a\nb>kept",
        ". leading-and-trailing ! ",
      ].each do |heading_html|
        expected = legacy_slugify_heading_anchor.call(heading_html)
        expect(described_class.slugify_heading_anchor(heading_html)).to eq(expected), heading_html.inspect
        expect(AgentSessionRenderers::HeadingAnchors.slugify(heading_html)).to eq(expected), heading_html.inspect
      end
    end

    it "declines non-UTF-8 strings, non-Strings, surrogate entities, and out-of-domain code points" do
      [
        nil,
        :heading,
        ActiveSupport::SafeBuffer.new("Getting Started"),
        "Getting Started".b,
        "Getting Started".encode("US-ASCII"),
        "Getting Started".encode("UTF-16LE"),
        "invalid \xFF byte",
        "&#xD800;",
        "&#55296;",
        "circled Ⓐ",
      ].each do |input|
        expect(described_class.slugify_heading_anchor(input)).to be_nil, input.inspect
      end

      [nil, :heading, ActiveSupport::SafeBuffer.new("Getting <b>Started</b>"), "circled Ⓐ"].each do |input|
        expect(AgentSessionRenderers::HeadingAnchors.slugify(input))
          .to eq(legacy_slugify_heading_anchor.call(input)), input.inspect
      end
      expect { AgentSessionRenderers::HeadingAnchors.slugify("&#xD800;") }.to raise_error(ArgumentError)
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = [
        "", "Getting", "Started", "v2.0?", "example_now", "small-business", " ", "  ", "\t", "\n", "\r", "\0",
        "<code>", "</code>", "<em>", "</em>", "<a href=\"#x\">", "<span\nclass='y'>", "<unclosed", ">",
        "&amp;", "&apos;", "&quot;", "&lt;", "&gt;", "&nbsp;", "&#39;", "&#x27;", "&#X1F680;", "&#0065;", "&#1114111;",
        "Überblick", "Café", "İstanbul", "e\u0301", "ОΣ", "日本語", "カタカナ", "한글", "🎉", "—", "…", ":", "!", "?"
      ]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..8)) { tokens.sample(random: rng) }.join
        expected = legacy_slugify_heading_anchor.call(sample)
        actual = described_class.slugify_heading_anchor(sample)
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(actual).to eq(expected), message
        expect(AgentSessionRenderers::HeadingAnchors.slugify(sample)).to eq(expected), message
      end
    end
  end

  describe ".beautified_url (ApplicationHelper#beautified_url)" do
    let(:legacy_beautified_url) do
      lambda do |url|
        url.sub(%r{\A((https?|ftp):/)?/}, "").sub(/\?.*/, "").chomp("/")
      rescue StandardError
        url
      end
    end
    let(:helper_host) { Object.new.extend(ApplicationHelper) }

    it "matches ApplicationHelper#beautified_url across edge cases" do
      [
        "",
        "/",
        "//",
        "//github.com/",
        "/github.com//",
        "https://github.com",
        "http://github.com/",
        "ftp://files.example.com/pub/",
        "https://github.com?a=3",
        "https://github.com/?a=3&b=4",
        "https://github.com/rails",
        "https://github.com/rails/rails/?tab=readme",
        "https:/github.com/",
        "ftp:/files.example.com/",
        "HTTPS://github.com/",
        "https://github.com?a=1\nb=2/",
        "https://github.com/?a=1\n",
        "https://github.com?a=1\r\nb=2/",
        "https://github.com?a=1?b=2\n?c=3/",
        "https://例え.テスト/パス/?q=🎉/",
      ].each do |url|
        expected = legacy_beautified_url.call(url)
        expect(described_class.beautified_url(url)).to eq(expected), url.inspect
        expect(helper_host.beautified_url(url)).to eq(expected), url.inspect
      end
    end

    it "declines non-UTF-8 strings and non-Strings and preserves the helper's legacy result" do
      [
        nil,
        false,
        123,
        :url,
        ActiveSupport::SafeBuffer.new("https://github.com/"),
        "https://github.com/".b,
        "https://github.com/".encode("US-ASCII"),
        "https://github.com/".encode("UTF-16LE"),
        "https://github.com/\xFF",
      ].each do |input|
        expect(described_class.beautified_url(input)).to be_nil, input.inspect
        expect(helper_host.beautified_url(input)).to eq(legacy_beautified_url.call(input)), input.inspect
      end
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = [
        "", "https://", "http://", "ftp://", "HTTPS://", "https:/", "ftp:/", "/", "//",
        "github.com", "dev.to", "example.com/path", "/rails", "/pub/", "?", "?a=1", "&b=2",
        "?q=rust&page=2", "\n", "\r\n", "\r", "#frag", "例え.テスト", "🎉", ":"
      ]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..8)) { tokens.sample(random: rng) }.join
        expected = legacy_beautified_url.call(sample)
        actual = described_class.beautified_url(sample)
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(actual).to eq(expected), message
        expect(helper_host.beautified_url(sample)).to eq(expected), message
      end
    end
  end

  describe ".parse_emojis (Html::Parser#parse_emojis)" do
    let(:legacy_parse_emojis) do
      lambda do |html|
        out = html.dup
        out.gsub!(/:([\w+-]+):/) do |match|
          emoji = Emoji.find_by_alias(Regexp.last_match(1)) # rubocop:disable Rails/DynamicFindBy
          emoji.present? ? emoji.raw : match
        end
        out
      end
    end

    it "matches Emoji.find_by_alias across every single alias in the gemoji database" do
      Emoji.all.each do |emoji| # rubocop:disable Rails/FindEach
        emoji.aliases.each do |alias_name|
          token = ":#{alias_name}:"
          expect(described_class.parse_emojis(token)).to eq(emoji.raw), token
          wrapped = "prefix #{token} suffix"
          expect(described_class.parse_emojis(wrapped)).to eq("prefix #{emoji.raw} suffix"), wrapped
        end
      end
    end

    it "matches legacy regexp behavior on adjacent, overlapping, and unknown colon patterns" do
      cases = [
        "",
        "plain text without colons",
        "single : colon and trailing:",
        ":leading_only",
        "::",
        ":::",
        ":joy:",
        ":+1: :-1: :100: :e-mail: :non-potable_water: :1st_place_medal:",
        ":not_an_emoji:",
        ":not_an_emoji:joy:",
        ":not_an_emoji::joy:",
        ":joy:not_an_emoji:",
        ":joy::not_an_emoji:",
        ":joy:joy:",
        ":joy::joy:",
        ":::joy:::",
        ":hello world:joy:",
        ":JOY: :Joy: :joy:",
        "日本語 :joy: café 👨‍👩‍👧‍👦",
        "<p>Hello :joy: and <a href=\"https://dev.to:3000/:joy:\">:rocket:</a></p>",
      ]

      cases.each do |input|
        expected = legacy_parse_emojis.call(input)
        actual = described_class.parse_emojis(input)
        expect(actual).to eq(expected), input.inspect
        expect(Html::Parser.new(input.dup).parse_emojis.html).to eq(expected), input.inspect
      end

      unchanged = +"no emojis :not_a_valid_alias: here"
      expect(described_class.parse_emojis(unchanged)).to equal(unchanged)
    end

    it "declines non-Strings, SafeBuffer, and non-UTF-8 encodings while Html::Parser falls back cleanly" do
      [nil, false, 123, :joy, ActiveSupport::SafeBuffer.new(":joy:"), ":joy:".b,
       ":joy:".encode("US-ASCII"), ":joy:".encode("UTF-16LE"), +":joy:\xFF"].each do |input|
        expect(described_class.parse_emojis(input)).to be_nil, input.inspect
      end

      safe_buf = ActiveSupport::SafeBuffer.new("Hello :joy:!")
      expect(Html::Parser.new(safe_buf).parse_emojis.html).to eq("Hello 😂!")
      safe_buf_no_emoji = ActiveSupport::SafeBuffer.new("Hello world!")
      expect(Html::Parser.new(safe_buf_no_emoji).parse_emojis.html).to eq("Hello world!")
    end

    it "passes differential equivalence across 1,000 generated strings" do
      rng = Random.new(424_242)
      known_aliases = Emoji.all.flat_map(&:aliases)
      tokens = [
        ":", "::", ":::", "joy", "+1", "-1", "100", "rocket", "heart", "not_an_emoji", "unknown_123",
        "JOY", "hello world", " ", "\n", "<p>", "</p>", "<code>", "</code>", "日本語", "🎉",
        "https://dev.to:3000/path", "a_b-c+d"
      ]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..12)) do
          if rng.rand < 0.35
            ":#{known_aliases.sample(random: rng)}:"
          else
            tokens.sample(random: rng)
          end
        end.join

        expected = legacy_parse_emojis.call(sample)
        actual = described_class.parse_emojis(sample)
        expect(actual).to eq(expected), "iteration #{iteration}: #{sample.inspect}"
      end
    end
  end

  describe ".escape_colon_emojis_in_codeblock (Html::Parser#escape_colon_emojis_in_codeblock)" do
    let(:legacy_escape) do
      escape_fn = nil
      escape_fn = lambda do |html|
        html_doc = Nokogiri::HTML.fragment(html)
        html_doc.children.each do |el|
          next if el.name == "code"

          if el.search("code").empty?
            next if el.parent.blank?

            parsed_html = el.to_html.dup
            if parsed_html.present?
              parsed_html.gsub!(/:([\w+-]+):/) do |match|
                emoji = Emoji.find_by_alias(Regexp.last_match(1)) # rubocop:disable Rails/DynamicFindBy
                emoji.present? ? emoji.raw : match
              end
            end
            el.swap(parsed_html)
          else
            el.children = escape_fn.call(el.children.to_html)
          end
        end
        html_doc.to_html
      end
      escape_fn
    end

    it "matches legacy Nokogiri traversal across canonical HTML fragments with and without codeblocks" do
      canonical_cases = [
        "",
        "plain text :joy: and :+1:",
        "<code>:joy:</code>",
        "<code>:joy:</code><p>:joy:</p>",
        "<p>Hello :joy: and <code>:heart:</code> world :+1:!</p>",
        "<div class=\"highlight\"><pre class=\"highlight ruby\"><code>puts \":joy: :rocket:\"</code></pre></div>" \
        "<p>Outside :rocket: and <code>:fire:</code>!</p>",
        "<div><section><article><p>:joy: <code>:heart:</code> :+1:</p></article></section></div>",
        "<table>\n<thead><tr><th>:joy:</th></tr></thead>\n" \
        "<tbody><tr>\n<td><code>:joy:</code></td>\n<td>:+1:</td>\n</tr></tbody>\n</table>",
        "<ul>\n<li>:joy:</li>\n<li>\n<code>:joy:</code> and :+1:</li>\n</ul>",
        "<p>Line 1 :joy:<br>Line 2 <img src=\"https://dev.to/a.png\" alt=\"pic\"></p><hr>",
        "<p>:joy: <svg viewbox=\"0 0 24 24\"><path d=\"M0 0\"></path></svg></p>",
        "<p>Tom &amp; Jerry &lt;3 &gt; :joy: in <a href=\"https://dev.to/a?x=1&amp;y=2\">:rocket:</a></p>",
        "<p>:not_an_emoji:joy: vs :not_an_emoji::joy: and <code>:not_an_emoji::joy:</code></p>",
        "<pre><code>:joy:</code>\n</pre>",
      ]

      canonical_cases.each do |html|
        expected = legacy_escape.call(html)
        actual = described_class.escape_colon_emojis_in_codeblock(html)
        expect(actual).to eq(expected), html.inspect
        expect(Html::Parser.new(html.dup).escape_colon_emojis_in_codeblock.html).to eq(expected), html.inspect
      end
    end

    it "declines non-canonical HTML fragments and edge cases while Html::Parser preserves legacy output" do
      non_canonical_cases = [
        "<br/>",
        "<div/>",
        "<P>:joy:</P>",
        "<p CLASS=\"x\">:joy:</p>",
        "<p class='x'>:joy:</p>",
        "<p class=x>:joy:</p>",
        "<td nowrap>:joy:</td>",
        "<p class=\"a\" class=\"b\">:joy:</p>",
        "<ul><li></li><li>:joy:</li></ul>",
        "<div><p>:joy:</p><p>:+1:</p></div>",
        "<h2>hello<code>:heart:</code></h2>",
        "<p>&nbsp; &copy; &#39; &#128512; :joy:</p>",
        "<p>a & b :joy:</p>",
        "<p>a < b :joy:</p>",
        "<p>a\x01b :joy:</p>",
        "<p>a\fb :joy:</p>",
        "<p title=\"a\x07b\">:joy:</p>",
        "<p>a\uFFFEb :joy:</p>",
        "<p>a\uFFFFb :joy:</p>",
        "<p data-title=\":joy:\">Hello <code>:heart:</code> :+1:</p>",
        "<p data-title=\":joy:\">Hello :+1:</p>",
        "<code>outer <code>:joy:</code> inner</code>",
        "<!-- :joy: --><p>:joy:</p>",
        "<p>:joy:",
        "<p><b>:joy:</p></b>",
        "<custom-element>:joy:</custom-element>",
        "<a href=\"https://dev.to/hello world\">:joy:</a>",
      ]

      non_canonical_cases.each do |html|
        expect(described_class.escape_colon_emojis_in_codeblock(html)).to be_nil, html.inspect
        expected = legacy_escape.call(html)
        expect(Html::Parser.new(html.dup).escape_colon_emojis_in_codeblock.html).to eq(expected), html.inspect
      end

      [nil, false, 123, :sym, ActiveSupport::SafeBuffer.new("<p>:joy:</p>"), "<p>:joy:</p>".b,
       "<p>:joy:</p>".encode("UTF-16LE"), +"<p>:joy:\xFF</p>"].each do |input|
        expect(described_class.escape_colon_emojis_in_codeblock(input)).to be_nil, input.inspect
      end
    end

    it "passes differential equivalence across 1,000 generated canonical HTML fragments" do
      rng = Random.new(424_242)
      text_pieces = [
        "hello", " :joy: ", " :+1: ", " :not_an_emoji:joy: ", " :not_an_emoji::joy: ",
        " &amp; ", " &lt; ", " &gt; ", " 日本語 ", " 🚀 ", " plain text "
      ]
      inline_fragments = [
        -> { "<code>#{text_pieces.sample(random: rng)}</code>" },
        -> { "<strong>#{text_pieces.sample(random: rng)}</strong>" },
        -> { "<em>#{text_pieces.sample(random: rng)}<code>:joy:</code></em>" },
        -> { "<a href=\"https://dev.to/post?a=1&amp;b=2\">#{text_pieces.sample(random: rng)}</a>" },
        -> { "<span class=\"crayons\">#{text_pieces.sample(random: rng)}</span>" },
        -> { "<br>" },
        -> { "<img src=\"https://dev.to/img.png\" alt=\"alt\">" },
      ]
      block_fragments = [
        lambda do
          inner = Array.new(rng.rand(1..4)) do
            rng.rand < 0.5 ? text_pieces.sample(random: rng) : inline_fragments.sample(random: rng).call
          end.join
          "<p>#{inner}</p>"
        end,
        lambda do
          "<div class=\"highlight\"><pre class=\"highlight ruby\">" \
            "<code>#{text_pieces.sample(random: rng)}</code></pre></div>"
        end,
        -> { "<h2>#{text_pieces.sample(random: rng)}<code>:heart:</code> text</h2>" },
        -> { "<blockquote><p>#{text_pieces.sample(random: rng)}<code>:joy:</code></p></blockquote>" },
      ]

      native_hits = 0
      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..5)) { block_fragments.sample(random: rng).call }.join("\n")
        expected = legacy_escape.call(sample)
        actual = described_class.escape_colon_emojis_in_codeblock(sample)
        native_hits += 1 unless actual.nil?
        expect(actual).to eq(expected), "iteration #{iteration}: #{sample.inspect}"
      end

      expect(native_hits).to eq(1_000)
    end

    it "passes adversarial differential equivalence across 1,000 arbitrary HTML fragments" do
      rng = Random.new(987_654)
      tokens = [
        "<p>", "</p>", "<div>", "</div>", "<code>", "</code>", "<pre>", "</pre>",
        "<span>", "</span>", "<ul>", "</ul>", "<li>", "</li>", "<br>", "<br/>",
        "<a href=\"https://dev.to?a=1&amp;b=2\">", "<a href=':joy:'>", "</a>",
        ":joy:", ":+1:", ":not_an_emoji:joy:", ":not_an_emoji::joy:", "hello", " ", "\n",
        "&amp;", "&lt;", "&gt;", "&nbsp;", "&#39;", "&", "<", ">", "<!-- :joy: -->"
      ]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..10)) { tokens.sample(random: rng) }.join
        expected = legacy_escape.call(sample)
        native = described_class.escape_colon_emojis_in_codeblock(sample)
        expect(native || expected).to eq(expected), "iteration #{iteration}: #{sample.inspect}"
        expect(Html::Parser.new(sample.dup).escape_colon_emojis_in_codeblock.html)
          .to eq(expected), "iteration #{iteration}: #{sample.inspect}"
      end
    end
  end

  describe ".title_for_metadata (Article#title_for_metadata)" do
    let(:legacy_title_for_metadata) do
      lambda do |title|
        title.gsub(/\s*\n\s*/, " ").gsub(/\s+/, " ").strip
      end
    end

    it "matches Article#title_for_metadata across edge cases" do
      [
        "",
        "   ",
        "\t\n\r\v\f\0",
        "This is a regular title",
        "Line one\nLine two",
        "First paragraph\n\nSecond paragraph",
        "Line one\n\n\nLine two",
        "  \nLine one\nLine two\n  ",
        "Line one  \n  Line two  \n  \n  Paragraph two",
        "Check this out\nhttps://example.com\n\nMore text",
        "These are the best ways to write a quickie:\n\n- Make it short\n- Make it great\n- Make it magoo\n\n" \
        "This is how you do it.\n\nOr is it how you do it?\n\nI don't know, is it really?\n\n" \
        "Really?\nReally?\nI dunno.",
        "\0\t\n\r\v\f  hello\t\r\nworld  \0\n",
        "a\0 \0b",
        "a\u00A0\u3000b\nc",
        "日本語\n\n🎉\tタイトル",
      ].each do |title|
        expected = legacy_title_for_metadata.call(title)
        expect(described_class.title_for_metadata(title)).to eq(expected), title.inspect
        if defined?(Article) && Article.method_defined?(:title_for_metadata) && title.present?
          article = Article.new(type_of: "status", title: title)
          expect(article.title_for_metadata).to eq(expected), title.inspect
        end
      end
    end

    it "declines non-UTF-8 strings and non-Strings and preserves Article#title_for_metadata fallback" do
      [
        nil,
        false,
        123,
        :title,
        ActiveSupport::SafeBuffer.new("Line one\nLine two"),
        "Line one\nLine two".b,
        "Line one\nLine two".encode("US-ASCII"),
        "Line one\nLine two".encode("UTF-16LE"),
        +"Line one\nLine two\xFF",
      ].each do |input|
        expect(described_class.title_for_metadata(input)).to be_nil, input.inspect
      end

      if defined?(Article) && Article.method_defined?(:title_for_metadata)
        article = Article.new(type_of: "status")
        article.title = "Line one\nLine two".encode("US-ASCII")
        expect(article.title_for_metadata).to eq("Line one Line two")
      end
    end

    it "passes differential equivalence across 1,000 generated inputs" do
      rng = Random.new(424_242)
      tokens = [
        "", " ", "  ", "\t", "\n", "\r", "\r\n", "\n\n", "\v", "\f", "\0",
        "\u00A0", "\u2000", "\u3000", "Line one", "Paragraph", "- bullet",
        "https://example.com/path?a=1&b=2", "日本語", "🎉", "café", "a\0b"
      ]

      1_000.times do |iteration|
        sample = Array.new(rng.rand(1..10)) { tokens.sample(random: rng) }.join
        expected = legacy_title_for_metadata.call(sample)
        actual = described_class.title_for_metadata(sample)
        message = "iteration #{iteration}: #{sample.inspect}"
        expect(actual).to eq(expected), message
        if defined?(Article) && Article.method_defined?(:title_for_metadata) && sample.present?
          article = Article.new(type_of: "status", title: sample)
          expect(article.title_for_metadata).to eq(expected), message
        end
      end
    end
  end
end
