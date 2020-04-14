require "rails_helper"

RSpec.describe DataSync::Elasticsearch::Article, type: :service do
  let(:article) { create(:article) }

  it "defines necessary constants" do
    expect(described_class::RELATED_DOCS).not_to be_nil
    expect(described_class::SHARED_FIELDS).not_to be_nil
  end

  describe "#sync_related_documents" do
    it "removes docs from elasticsearch if article is unpublished" do
      allow(article).to receive(:saved_changes).and_return(published: [true, false])
      reaction = create(:reaction, reactable: article, category: "readinglist")
      sidekiq_perform_enqueued_jobs
      expect(reaction.elasticsearch_doc).not_to be_nil

      article.update_column(:published, false)

      described_class.new(article).call
      sidekiq_perform_enqueued_jobs
      expect { reaction.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    end
  end
end
