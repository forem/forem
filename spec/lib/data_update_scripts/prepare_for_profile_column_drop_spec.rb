require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201103050112_prepare_for_profile_column_drop.rb",
)

describe DataUpdateScripts::PrepareForProfileColumnDrop do
  context "when using only DEV profile fields" do
    it "migrates data from the user to the profile", :aggregate_failures do
      summary = "I hack on profiles a lot"
      user = create(:user, summary: summary)

      expect(user.profile).not_to respond_to(:summary)
      described_class.new.run
      expect(user.profile.reload.summary).to eq(summary)
    end
  end

  context "when a Forem used additional profile fields" do
    let!(:user) { create(:user) }

    before do
      create(:profile_field, label: "Doge Test")
      Profile.refresh_attributes!
      user.profile.update(doge_test: "Such update, much wow!")
    end

    it "migrates data and keeps existing data intact", :aggregate_failures do
      described_class.new.run
      expect(user.profile.reload.data.keys.size).to eq(11)
      expect(user.profile.data).to have_key("doge_test")
    end
  end
end
