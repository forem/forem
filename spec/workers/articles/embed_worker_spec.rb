require "rails_helper"

RSpec.describe Articles::EmbedWorker, type: :worker do
  let(:article) { create(:article, title: "Ruby on Rails", tags: "ruby, rails") }
  let(:worker) { described_class.new }
  let(:ai_client) { instance_double(Ai::Base) }
  let(:embedding) { Array.new(768, 0.1) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
    allow(ai_client).to receive(:embed).and_return(embedding)
  end

  describe "#perform" do
    it "fetches embedding and updates article semantic interests" do
      expect(ai_client).to receive(:embed).with(include("Ruby on Rails")).and_return(embedding)
      
      worker.perform(article.id)
      
      article.reload
      expect(article.semantic_interests).to be_present
      expect(article.semantic_interests.keys).to include(*Ai::InterestExtractor::DIMENSIONS.sample(3))
    end

    it "does nothing if article does not exist" do
      expect(ai_client).not_to receive(:embed)
      worker.perform(999999)
    end

    it "does nothing if article already has semantic interest" do
      article.update_column(:semantic_interests, { "backend_engineering" => 0.9 })
      expect(ai_client).not_to receive(:embed)
      worker.perform(article.id)
    end

    it "uses full body markdown for embedding" do
      article.update_column(:body_markdown, "Detailed content about framework architecture.")
      
      expect(ai_client).to receive(:embed) do |text|
        expect(text).to include("Detailed content about framework architecture")
        embedding
      end

      worker.perform(article.id)
    end
  end
end
