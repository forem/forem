require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20230517132257_populate_suggested_tags_from_settings.rb",
)

describe DataUpdateScripts::PopulateSuggestedTagsFromSettings do
  let(:suggested_tags) { %w[some tags go here] }

  before do
    create(:tag, name: "some")
    create(:tag, name: "tags")
    create(:tag, name: "go")
    create(:tag, name: "here")
    create(:tag, name: "otherwise")
    create(:tag, name: "nothing")
  end

  around do |example|
    original = described_class.suggested_tags
    described_class.suggested_tags = suggested_tags
    example.run
    described_class.suggested_tags = original
  end

  it "updates tags to use new boolean attribute (instead of settings)" do
    described_class.new.run
    expect(Tag.where(suggested: true).pluck(:name)).to include(*%w[some tags go here])
  end
end
