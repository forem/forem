require "rails_helper"

RSpec.describe Articles::BustMultipleCachesWorker, type: :worker do
  describe "#perform" do
    # Explicitly create article before the test is invoked, since
    # creating an article will invoke EdgeCache::Bust#call in a callback.
    let!(:article) { create(:article) }
    let(:path) { article.path }
    let(:worker) { subject }
    let(:cache_bust) { instance_double(EdgeCache::Bust) }

    before do
      allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)
      allow(cache_bust).to receive(:call).with(path)
      allow(cache_bust).to receive(:call).with("#{path}?i=i")
    end

    it "busts cache" do
      worker.perform([article.id])

      expect(cache_bust).to have_received(:call).with(path).once
      expect(cache_bust).to have_received(:call).with("#{path}?i=i").once
    end
  end
end
