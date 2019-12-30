require "rails_helper"

RSpec.describe Articles::BustCacheJob, type: :job do
  include_examples "#enqueues_job", "articles_bust_cache", 1

  describe "#perform_now" do
    let(:cache_buster) { double }

    before { allow(cache_buster).to receive(:bust_article) }

    context "with article" do
      let_it_be(:article) { double }
      let_it_be(:article_id) { 1 }

      before do
        allow(Article).to receive(:find_by).with(id: article_id).and_return(article)
      end

      it "async busts cache" do
        described_class.perform_now(article_id, cache_buster)
        expect(cache_buster).to have_received(:bust_article).with(article)
      end
    end

    context "without article" do
      it "does not error" do
        expect { described_class.perform_now(nil, cache_buster) }.not_to raise_error
      end

      it "does not bust cache" do
        described_class.perform_now(nil, cache_buster)
        expect(cache_buster).not_to have_received(:bust_article)
      end
    end
  end
end
