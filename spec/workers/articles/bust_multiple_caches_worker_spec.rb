require "rails_helper"

RSpec.describe Articles::BustMultipleCachesWorker, type: :worker do
  describe "#perform" do
    # Explicitly create article before the test is invoked, since
    # creating an article will invoke EdgeCache::Bust#call in a callback.
    let!(:article) { create(:article) }
    let(:path) { article.path }
    let(:worker) { subject }
    let(:buster) { instance_double(EdgeCache::Buster) }

    before do
      allow(EdgeCache::Buster).to receive(:new).and_return(buster)
      allow(buster).to receive(:bust).with(path)
      allow(buster).to receive(:bust).with("#{path}?i=i")
    end

    it "busts cache" do
      worker.perform([article.id])

      expect(buster).to have_received(:bust).with(path).once
      expect(buster).to have_received(:bust).with("#{path}?i=i").once
    end
  end
end
