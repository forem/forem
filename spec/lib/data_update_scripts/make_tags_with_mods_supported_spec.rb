require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201030015634_make_tags_with_mods_supported.rb",
)

describe DataUpdateScripts::MakeTagsWithModsSupported do
  let!(:tag1) { create(:tag, name: "Test1", supported: false) }
  let!(:tag2) { create(:tag, name: "Test2", supported: false) }
  let!(:user) { create(:user) }

  it "sets tags with moderators to supported", :aggregate_failures do
    user.add_role(:tag_moderator, tag1)

    expect do
      described_class.new.run
    end.to change { tag1.reload.supported? }.from(false).to(true)
    expect(tag2.reload.supported).to be false
  end
end
