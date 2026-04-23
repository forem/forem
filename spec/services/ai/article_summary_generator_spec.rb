require "rails_helper"

RSpec.describe Ai::ArticleSummaryGenerator, type: :service do
  let(:article) { create(:article) }
  let(:ai_client) { instance_double(Ai::Base) }
  let(:generator) { described_class.new(article) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
  end

  def words_of(count)
    Array.new(count) { |i| "word#{i}" }.join(" ")
  end

  describe "#call" do
    it "writes summary and metadata when AI returns a valid-length response" do
      summary = words_of(55)
      allow(ai_client).to receive(:call).and_return(summary)
      original_updated_at = article.updated_at

      Timecop.freeze(1.hour.from_now) do
        generator.call
      end

      article.reload
      expect(article.ai_summary).to eq(summary)
      expect(article.ai_summary_prompt_version).to eq(Ai::ArticleSummaryGenerator::VERSION)
      expect(article.ai_summary_generated_at).to be_present
      expect(article.updated_at).to be > original_updated_at
    end

    it "strips surrounding quotes that the AI may have added" do
      allow(ai_client).to receive(:call).and_return("\"#{words_of(55)}\"")

      generator.call

      expect(article.reload.ai_summary).to eq(words_of(55))
    end

    it "returns without writing if response is blank" do
      allow(ai_client).to receive(:call).and_return("")

      expect { generator.call }.not_to change { article.reload.ai_summary }
    end

    it "retries and succeeds when first response has invalid word count" do
      too_short = words_of(20)
      valid = words_of(55)
      allow(ai_client).to receive(:call).and_return(too_short, valid)

      generator.call

      expect(article.reload.ai_summary).to eq(valid)
      expect(ai_client).to have_received(:call).twice
    end

    it "retries up to MAX_RETRIES and fails gracefully" do
      too_long = words_of(100)
      allow(ai_client).to receive(:call).and_return(too_long)

      expect { generator.call }.not_to change { article.reload.ai_summary }
      expect(ai_client).to have_received(:call).exactly(Ai::ArticleSummaryGenerator::MAX_RETRIES + 1).times
    end

    it "defines a VERSION constant for audit logging" do
      expect(described_class::VERSION).to be_a(String)
      expect(described_class::VERSION).not_to be_empty
    end
  end
end
