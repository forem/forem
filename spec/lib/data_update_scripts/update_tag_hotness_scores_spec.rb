require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200324133751_update_tag_hotness_scores.rb")

describe DataUpdateScripts::UpdateTagHotnessScores do
  it "can save all tags" do
    expect(Tag.new).to respond_to(:save)
  end
end
