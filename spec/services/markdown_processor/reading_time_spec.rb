require "rails_helper"

RSpec.describe MarkdownProcessor::ReadingTime, type: :service do
  let(:sample_markdown) do
    <<~MARKDOWN
      ## Building Fast Native Extensions

      #{Array.new(300, 'performance').join(' ')}
    MARKDOWN
  end

  describe ".calculate" do
    it "computes reading time via ForemNative.calculate_reading_time" do
      allow(ForemNative).to receive(:calculate_reading_time).and_call_original

      result = described_class.calculate(sample_markdown)
      expected = (sample_markdown.split(/\W+/).count / described_class::WORDS_READ_PER_MINUTE).ceil

      expect(result).to eq(2)
      expect(result).to eq(expected)
      expect(ForemNative).to have_received(:calculate_reading_time).with(sample_markdown)
    end

    it "handles nil and empty input safely" do
      expect(described_class.calculate(nil)).to eq(0)
      expect(described_class.calculate("")).to eq(0)
      expect(described_class.calculate("   ")).to eq(0)
    end
  end
end
