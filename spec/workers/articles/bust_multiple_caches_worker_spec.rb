require "rails_helper"

RSpec.describe Articles::BustMultipleCachesWorker, type: :worker do
  describe "#perform" do
    # Explicitly create article before the test is invoked, since
    # creating an article will invoke CacheBuster#bust in a callback.
    let!(:article) { create(:article) }
    let(:path) { article.path }
    let(:worker) { subject }

    it "busts cache" do
      allow(CacheBuster).to receive(:bust)

      worker.perform([article.id])

      expect(CacheBuster).to have_received(:bust).with(path).once
      expect(CacheBuster).to have_received(:bust).with("#{path}?i=i").once
    end
  end
end
