require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20230428105252_remove_ahoy_comment_section_viewable_events.rb",
)

describe DataUpdateScripts::RemoveAhoyCommentSectionViewableEvents do
  let!(:cv_event) { create(:ahoy_event, name: "Comment section viewable") }
  let!(:other_event) { create(:ahoy_event) }

  it "removes 'comment viewable' ahoy events" do
    described_class.new.run
    expect(Ahoy::Event.find_by(id: cv_event.id)).to be_nil
  end

  it "keeps other ahoy_events" do
    described_class.new.run
    expect(Ahoy::Event.find_by(id: other_event.id)).to be_present
  end
end
