require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210622145212_backfill_forem_consumer_app_team_id.rb",
)

describe DataUpdateScripts::BackfillForemConsumerAppTeamId do
  def forem_ios_consumer_app
    ConsumerApp.find_or_create_by(app_bundle: ConsumerApp::FOREM_BUNDLE, platform: :ios)
  end

  before do
    consumer_app = forem_ios_consumer_app
    consumer_app.update_columns(team_id: nil)
    mock_rpush(consumer_app)
  end

  it "adds the team_id to a the Forem iOS Consumer App" do
    # The team_id is expected be nil at the start of the test
    consumer_app = forem_ios_consumer_app
    expect(consumer_app.team_id).to be_nil

    expect { described_class.new.run }
      .to change { consumer_app.reload.team_id }
      .from(nil).to(ConsumerApp::FOREM_TEAM_ID)
  end

  it "doesn't affect other Consumer App Team IDs", :aggregate_failures do
    custom_team_id = "ABC123"
    custom_consumer_app = create(:consumer_app, team_id: custom_team_id)

    expect { described_class.new.run }
      .not_to change { custom_consumer_app.reload.team_id }
  end
end
