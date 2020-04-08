require "rails_helper"

RSpec.describe DataSync::Elasticsearch::Article, type: :service do
  let(:article) { create(:article) }

  describe "#call" do
    it "reindexes RELATED_DOCS when sync is needed " do
      syncer = described_class.new(article, title: %w[old_title new_title])
      described_class::RELATED_DOCS.each do |method_name|
        allow(syncer).to receive(method_name).and_call_original
      end
      syncer.call
      described_class::RELATED_DOCS.each do |method_name|
        expect(syncer).to have_received(method_name)
      end
    end

    it "does not reindex when sync is not needed" do
      syncer = described_class.new(article, page_views_count: [nil, 1])
      described_class::RELATED_DOCS.each { |method_name| allow(syncer).to receive(method_name) }
      syncer.call
      described_class::RELATED_DOCS.each do |method_name|
        expect(syncer).not_to have_received(method_name)
      end
    end

    it "removes docs from elasticsearch if article is unpublished" do
      reaction = create(:reaction, reactable: article, category: "readinglist")
      sidekiq_perform_enqueued_jobs
      expect(reaction.elasticsearch_doc).not_to be_nil

      article.update_column(:published, false)

      described_class.new(article, published: [true, false]).call
      sidekiq_perform_enqueued_jobs
      expect { reaction.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    end
  end
end
