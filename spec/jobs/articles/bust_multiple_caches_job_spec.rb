require "rails_helper"

RSpec.describe Articles::BustMultipleCachesJob, type: :job do
  include_examples "#enqueues_job", "articles_bust_multiple_caches", [1, 2]

  describe "#perform_now" do
    it "busts cache" do
      article = create(:article)
      path = article.path

      cache_buster = double
      allow(cache_buster).to receive(:bust)

      described_class.perform_now([article.id], cache_buster)
      expect(cache_buster).to have_received(:bust).with(path).once
      expect(cache_buster).to have_received(:bust).with(path + "?i=i").once
    end
  end
end
