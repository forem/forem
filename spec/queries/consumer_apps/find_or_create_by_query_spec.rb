require "rails_helper"

RSpec.describe ConsumerApps::FindOrCreateByQuery, type: :query do
  context "when fetching the Forem app" do
    it "recreates the record if it doesn't exist" do
      expect(ConsumerApp.count).to eq(0)

      expect do
        app = described_class.call(
          app_bundle: ConsumerApp::FOREM_BUNDLE,
          platform: :ios,
        )
        expect(app).to be_instance_of(ConsumerApp)
        expect(app.team_id).to eq(ConsumerApp::FOREM_TEAM_ID)
      end.to change(ConsumerApp, :count).by(1)
    end
  end

  context "when fetching other ConsumerApps" do
    it "returns the requested ConsumerApp" do
      consumer_app = create(:consumer_app)
      expect do
        result = described_class.call(
          app_bundle: consumer_app.app_bundle,
          platform: consumer_app.platform,
        )
        expect(result).to be_instance_of(ConsumerApp)
        expect(result.id).to eq(consumer_app.id)
      end.not_to change(ConsumerApp, :count)
    end
  end

  context "when/if a failure occurs" do
    it "logs to ForemStatsClient if the default ConsumerApp create fails" do
      allow(ForemStatsClient).to receive(:increment)

      # Destroy any existing ConsumerApps - so the test is absolutely certain
      ConsumerApp.destroy_all
      # Create the Forem iOS ConsumerApp with an empty team_id
      ConsumerApp.create!(app_bundle: ConsumerApp::FOREM_BUNDLE, platform: :ios)
      # This will raise an error bc the Forem app_bundle+platform already exists
      described_class.call(
        app_bundle: ConsumerApp::FOREM_BUNDLE,
        platform: :ios,
      )

      expect(ForemStatsClient).to have_received(:increment).at_least(:once)
    end
  end
end
