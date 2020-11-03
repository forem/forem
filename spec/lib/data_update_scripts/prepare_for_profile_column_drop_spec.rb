require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201103050112_prepare_for_profile_column_drop.rb",
)

describe DataUpdateScripts::PrepareForProfileColumnDrop do
  context "when using only DEV profile fields" do
    it "migrates data from the user to the profile" do
      user = create(:user)

      expect do
        described_class.new.run
      end.to change { user.profile.reload.data.keys.size }.to(30)
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
      expect(user.profile.reload.data.keys.size).to eq(31)
      expect(user.profile.data).to have_key("doge_test")
    end
  end
end
