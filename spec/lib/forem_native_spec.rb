require "rails_helper"

RSpec.describe ForemNative do
  before do
    if !described_class.native_loaded? && ForemNative::Builder.cargo_available?
      ForemNative::Builder.compile!
      described_class.load_native!
    end
  end

  describe ".available? and .with_fallback" do
    it "reports native availability when compiled and toggles cleanly inside .with_fallback" do
      skip "Rust toolchain (cargo) is not available in this environment" unless ForemNative::Builder.cargo_available?

      expect(described_class.native_loaded?).to be(true)
      expect(described_class.available?).to be(true)

      described_class.with_fallback do
        expect(described_class.available?).to be(false)
        expect(described_class.calculate_reading_time("hello world")).to eq(1)
      end

      expect(described_class.available?).to be(true)
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

    it "matches RubyFallback across all edge cases and boundary conditions" do
      edge_cases.each do |input|
        expected_words = ForemNative::RubyFallback.split_word_count(input)
        expected_minutes = ForemNative::RubyFallback.calculate_reading_time(input)

        expect(described_class.split_word_count(input)).to eq(expected_words),
                                                           "word count mismatch for #{input.inspect}"
        expect(described_class.calculate_reading_time(input)).to eq(expected_minutes),
                                                                 "reading time mismatch for #{input.inspect}"

        described_class.with_fallback do
          expect(described_class.split_word_count(input)).to eq(expected_words)
          expect(described_class.calculate_reading_time(input)).to eq(expected_minutes)
        end
      end
    end

    it "passes differential equivalence across 1,000 generated Markdown and Unicode inputs" do
      skip "Native extension not loaded" unless described_class.available?

      tokens = [
        "word", "Rust", "Ruby_3_3", "0", "42", " ", "  ", "\n", "\r\n", "\t",
        ".", ",", "!", "-", "_", "`", "```", "|", "\\|", "é", "ü", "🚀", "中",
        "[link](https://dev.to)", "{% raw %}", "## Heading"
      ]
      rng = Random.new(20_261_023)

      1_000.times do |iteration|
        piece_count = rng.rand(0..120)
        sample = Array.new(piece_count) { tokens.sample(random: rng) }.join

        expected_words = ForemNative::RubyFallback.split_word_count(sample)
        actual_words = ForemNative::Native.split_word_count(sample)
        expect(actual_words).to eq(expected_words),
                                "Differential word_count mismatch at iteration #{iteration} for #{sample.inspect}"

        expected_time = ForemNative::RubyFallback.calculate_reading_time(sample)
        actual_time = ForemNative::Native.calculate_reading_time(sample)
        expect(actual_time).to eq(expected_time),
                               "Differential reading_time mismatch at iteration #{iteration} for #{sample.inspect}"
      end
    end
  end
end
