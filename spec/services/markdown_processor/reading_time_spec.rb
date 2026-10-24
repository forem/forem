require "rails_helper"

RSpec.describe MarkdownProcessor::ReadingTime, type: :service do
  let(:sample_markdown) do
    <<~MARKDOWN
      ## Building Fast Native Extensions

      #{Array.new(300, 'performance').join(' ')}
    MARKDOWN
  end

  describe ".calculate" do
    context "when :native_reading_time feature flag is disabled (default)" do
      before { FeatureFlag.disable(:native_reading_time) }

      it "computes reading time via the legacy Ruby implementation" do
        allow(ForemNative).to receive(:calculate_reading_time)

        result = described_class.calculate(sample_markdown)

        expect(result).to eq(2)
        expect(ForemNative).not_to have_received(:calculate_reading_time)
      end
    end

    context "when :native_reading_time feature flag is enabled" do
      before { FeatureFlag.enable(:native_reading_time) }
      after { FeatureFlag.disable(:native_reading_time) }

      it "delegates to ForemNative.calculate_reading_time when native extension is available" do
        allow(ForemNative).to receive(:available?).and_return(true)
        allow(ForemNative).to receive(:calculate_reading_time).and_call_original

        result = described_class.calculate(sample_markdown)

        expect(result).to eq(described_class.legacy_ruby_calculate(sample_markdown))
        expect(ForemNative).to have_received(:calculate_reading_time).with(sample_markdown)
      end

      it "falls back transparently to legacy_ruby_calculate when native extension is unavailable" do
        ForemNative.with_fallback do
          expect(described_class.native_enabled?).to be(false)
          expect(described_class.calculate(sample_markdown)).to eq(2)
        end
      end
    end

    it "handles nil and empty input safely" do
      expect(described_class.calculate(nil)).to eq(0)
      expect(described_class.calculate("")).to eq(0)
      expect(described_class.calculate("   ")).to eq(0)
    end
  end
end
