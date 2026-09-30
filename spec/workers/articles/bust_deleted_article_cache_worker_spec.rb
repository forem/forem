require "rails_helper"

RSpec.describe Articles::BustDeletedArticleCacheWorker, type: :worker do
  let(:article) { create(:article, tags: "ruby, rails", with_main_image: false) }

  include_examples "#enqueues_on_correct_queue", "high_priority", [{ "id" => 1 }]

  describe ".attributes_for" do
    it "only captures the attributes needed to bust the article's caches, as JSON-safe values" do
      attributes = described_class.attributes_for(article)

      expect(attributes.keys).to match_array(described_class::ATTRIBUTES)
      expect(attributes).to include("id" => article.id, "path" => article.path, "user_id" => article.user_id)
      expect(attributes["published_at"]).to be_a(String)
      expect(attributes).not_to have_key("body_markdown")
    end
  end

  describe "#perform" do
    before { allow(EdgeCache::BustArticle).to receive(:call) }

    it "busts the caches of a copy of the deleted article rebuilt from its attributes", :aggregate_failures do
      attributes = described_class.attributes_for(article)
      article.delete

      described_class.new.perform(attributes)

      expect(EdgeCache::BustArticle).to have_received(:call) do |rebuilt|
        expect(rebuilt).to be_a(Article)
        expect(rebuilt).not_to be_persisted
        expect(rebuilt.id).to eq(article.id)
        expect(rebuilt.record_key).to eq(article.record_key)
        expect(rebuilt.path).to eq(article.path)
        expect(rebuilt.tag_list).to match_array(%w[ruby rails])
        expect(rebuilt.published_at).to be_within(1.second).of(article.published_at)
      end
    end

    it "busts the tag pages of a recently published deleted article" do
      allow(EdgeCache::BustArticle).to receive(:call).and_call_original
      cache_bust = instance_double(EdgeCache::Bust, call: nil)
      allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)

      attributes = described_class.attributes_for(article)
      article.delete

      described_class.new.perform(attributes)

      expect(cache_bust).to have_received(:call).with("/t/ruby/latest")
      expect(cache_bust).to have_received(:call).with("/t/rails/latest")
    end

    it "ignores unexpected attributes" do
      attributes = described_class.attributes_for(article).merge("body_markdown" => "hello")

      expect { described_class.new.perform(attributes) }.not_to raise_error
    end
  end
end
