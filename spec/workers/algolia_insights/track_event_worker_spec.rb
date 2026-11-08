require "rails_helper"

RSpec.describe AlgoliaInsights::TrackEventWorker do
  describe "sidekiq_options" do
    it "runs on medium_priority with retry disabled", :aggregate_failures do
      expect(described_class.get_sidekiq_options["queue"]).to eq(:medium_priority)
      expect(described_class.get_sidekiq_options["retry"]).to be(false)
      expect(described_class.get_sidekiq_options["tags"]).to eq(["algolia"])
    end
  end

  describe "#perform" do
    let(:algolia_service) { instance_double(AlgoliaInsightsService, track_event: nil) }

    before do
      allow(AlgoliaInsightsService).to receive(:new).and_return(algolia_service)
    end

    it "delegates to AlgoliaInsightsService#track_event and restores subforem_id context", :aggregate_failures do
      described_class.new.perform("view", "Article Viewed", 42, 99, "Article_test", 1_700_000_000_000, "qid", [2], 7)

      expect(RequestStore.store[:subforem_id]).to eq(7)
      expect(algolia_service).to have_received(:track_event).with(
        "view",
        "Article Viewed",
        42,
        99,
        "Article_test",
        1_700_000_000_000,
        "qid",
        [2],
      )
    end
  end
end
