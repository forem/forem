require "rails_helper"

RSpec.describe ForemNative do
  let(:legacy_split_word_count) do
    ->(content) { content.to_s.split(/\W+/).count }
  end

  let(:legacy_calculate_reading_time) do
    ->(content) { (legacy_split_word_count.call(content) / 275.0).ceil }
  end

  describe ".available?" do
    it "loads the compiled Rust native extension directly" do
      expect(described_class.available?).to be(true)
      expect(described_class.native_loaded?).to be(true)
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
end
