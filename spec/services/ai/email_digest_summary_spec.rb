require "rails_helper"

RSpec.describe Ai::EmailDigestSummary, type: :service do
  let(:articles) do
    [
      instance_double(Article, id: 1, title: "Title 1", description: "Desc 1", cached_tag_list: "ruby"),
      instance_double(Article, id: 2, title: "Title 2", description: "Desc 2", cached_tag_list: "rails"),
    ]
  end
  let(:ai_client) { instance_double(Ai::Base) }
  let(:service) { described_class.new(articles, ai_client: ai_client) }

  describe "#generate" do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      allow(ai_client).to receive(:call).and_return("AI generated summary")
      Rails.cache.clear
    end

    it "generates a summary using AI" do
      result = service.generate
      expect(result).to eq("AI generated summary")
      expect(ai_client).to have_received(:call).once
    end

    it "caches the result" do
      service.generate
      service.generate
      expect(ai_client).to have_received(:call).once
    end

    it "is order-independent for caching" do
      service.generate

      reordered_articles = articles.reverse
      new_service = described_class.new(reordered_articles, ai_client: ai_client)
      new_service.generate

      expect(ai_client).to have_received(:call).once
    end

    it "returns nil if articles are empty" do
      empty_service = described_class.new([])
      expect(empty_service.generate).to be_nil
    end

    it "returns nil and logs error if AI client fails" do
      allow(ai_client).to receive(:call).and_raise(StandardError, "AI Error")
      expect(Rails.logger).to receive(:error).with(/AI Digest Summary generation failed/)

      expect(service.generate).to be_nil
    end
  end
end
