require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210622145212_backfill_forem_consumer_app_team_id.rb",
)

describe DataUpdateScripts::BackfillForemConsumerAppTeamId do
  def forem_ios_consumer_app
    ConsumerApp.find_by(app_bundle: ConsumerApp::FOREM_BUNDLE, platform: :ios)
  end

  before do
    # Destroy any existing ConsumerApps - so the test is absolutely certain
    ConsumerApp.destroy_all
    # Create the Forem iOS ConsumerApp with an empty team_id
    ConsumerApp.create!(app_bundle: ConsumerApp::FOREM_BUNDLE, platform: :ios)
  end

  it "adds the team_id to a the Forem iOS Consumer App" do
    # The team_id is expected be nil at the start of the test
    expect(forem_ios_consumer_app.team_id).to be_nil

    described_class.new.run

    expect(forem_ios_consumer_app.team_id).to eq(ConsumerApp::FOREM_TEAM_ID)
  end

  it "doesn't affect other Consumer App Team IDs", :aggregate_failures do
    custom_team_id = "ABC123"
    custom_consumer_app = create(:consumer_app, team_id: custom_team_id)

    described_class.new.run

    expect(custom_consumer_app.reload.team_id).to eq(custom_team_id)
    expect(forem_ios_consumer_app.team_id).to eq(ConsumerApp::FOREM_TEAM_ID)
  end
end
