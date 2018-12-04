require "rails_helper"

RSpec.describe TagAdjustmentCreationService do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:tag) { create(:tag) }

  before do
    user.add_role(:tag_moderator, tag)
    @tag_adjustment = described_class.new(user, {
      adjustment_type: "removal",
      status: "committed",
      tag_name: tag.name,
      article_id: article.id,
      reason_for_adjustment: "Test"
    }).create
  end

  it "creates tag adjustment" do
    expect(@tag_adjustment).to be_valid
    expect(@tag_adjustment.tag_id).to eq(tag.id)
    expect(@tag_adjustment.status).to eq("committed")
  end

  it "creates notification" do
    expect(Notification.last.user_id).to eq(article.user_id)
    expect(Notification.last.json_data["adjustment_type"]).to eq(@tag_adjustment.adjustment_type)
  end
end
