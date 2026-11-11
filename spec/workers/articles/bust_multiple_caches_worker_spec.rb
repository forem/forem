require "rails_helper"

RSpec.describe Articles::BustMultipleCachesWorker, type: :worker do
  describe "#perform" do
    let!(:article) { create(:article) }
    let(:worker) { subject }

    before do
      allow(EdgeCache::PurgeByKey).to receive(:call)
    end

    it "purges article surrogate keys without querying paths eagerly", :aggregate_failures do
      worker.perform([article.id])

      expect(EdgeCache::PurgeByKey).to have_received(:call).once do |keys, fallback_paths:|
        expect(keys).to eq(["articles/#{article.id}"])
        expect(fallback_paths).to respond_to(:call)
        expect(fallback_paths.call).to eq([article.path])
      end
    end

    it "does nothing when article_ids is empty" do
      worker.perform([])

      expect(EdgeCache::PurgeByKey).not_to have_received(:call)
    end
  end
end
