require "rails_helper"

RSpec.describe Articles::BustCacheWorker, type: :worker do
  describe "#perform" do
    let(:article) { FactoryBot.create(:article) }
    let(:cache_buster) { double }
    let(:worker) { subject }
    let(:buster) { "CacheBuster" }

    before do
      allow(buster).to receive(:constantize).and_return(cache_buster)
      allow(cache_buster).to receive(:bust_article)
    end

    context "with cache buster defined" do
      it "busts cache with defined buster" do
        new_buster = "NewBuster"
        allow(new_buster).to receive(:constantize).and_return(cache_buster)
        allow(cache_buster).to receive(:bust_article)
        worker.perform(article.id, new_buster)
        expect(cache_buster).to have_received(:bust_article).with(article)
      end
    end

    context "without cache buster defined" do
      it "busts cache with default" do
        allow(CacheBuster).to receive(:bust_article)
        worker.perform(article.id)
        expect(CacheBuster).to have_received(:bust_article).with(article)
      end
    end

    context "without article" do
      it "does not error" do
        expect { worker.perform(nil, buster) }.not_to raise_error
      end

      it "does not bust cache" do
        worker.perform(nil)
        expect(cache_buster).not_to have_received(:bust_article)
      end
    end
  end
end
