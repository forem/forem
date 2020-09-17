require "rails_helper"

class NewBuster
  def self.bust_article(*); end
end

RSpec.describe Articles::BustCacheWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    context "with article" do
      let(:article) { double }
      let(:article_id) { 1 }

      before do
        allow(Article).to receive(:find_by).with(id: article_id).and_return(article)
      end

      it "with cache buster defined busts cache with defined buster" do
        allow(NewBuster).to receive(:bust_article)
        worker.perform(article_id, "NewBuster")
        expect(NewBuster).to have_received(:bust_article).with(article)
      end

      it "without cache buster defined busts cache with default" do
        allow(CacheBuster).to receive(:bust_article)
        worker.perform(article_id)
        expect(CacheBuster).to have_received(:bust_article).with(article)
      end
    end

    context "without article" do
      it "does not error" do
        expect { worker.perform(nil, "CacheBuster") }.not_to raise_error
      end

      it "does not bust cache" do
        allow(CacheBuster).to receive(:bust_article)
        worker.perform(nil)
        expect(CacheBuster).not_to have_received(:bust_article)
      end
    end
  end
end
