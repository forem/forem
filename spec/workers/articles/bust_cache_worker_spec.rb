require "rails_helper"

RSpec.describe Articles::BustCacheWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    context "with article" do
      let(:article) { double }
      let(:article_id) { 1 }

      before do
        allow(Article).to receive(:find_by).with(id: article_id).and_return(article)
        allow(EdgeCache::BustArticle).to receive(:call).with(article)
      end

      it "busts the cache" do
        worker.perform(article_id)
        expect(EdgeCache::BustArticle).to have_received(:call).with(article)
      end
    end

    context "without article" do
      before do
        allow(EdgeCache::BustArticle).to receive(:call)
      end

      it "does not error" do
        expect { worker.perform(nil) }.not_to raise_error
      end

      it "does not bust cache" do
        worker.perform(nil)
        expect(EdgeCache::BustArticle).not_to have_received(:call)
      end
    end
  end
end
