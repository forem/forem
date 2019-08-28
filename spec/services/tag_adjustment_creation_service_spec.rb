require "rails_helper"

RSpec.describe TagAdjustmentCreationService do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:tag) { create(:tag) }

  def create_tag_adjustment
    described_class.new(
      user,
      adjustment_type: "removal",
      status: "committed",
      tag_name: tag.name,
      article_id: article.id,
      reason_for_adjustment: "Test",
    ).create
  end

  before do
    user.add_role(:tag_moderator, tag)
  end

  it "creates tag adjustment" do
    tag_adjustment = create_tag_adjustment

    expect(tag_adjustment).to be_valid
    expect(tag_adjustment.tag_id).to eq(tag.id)
    expect(tag_adjustment.status).to eq("committed")
  end

  it "creates notification" do
    perform_enqueued_jobs do
      tag_adjustment = create_tag_adjustment
      expect(Notification.last.user_id).to eq(article.user_id)
      expect(Notification.last.json_data["adjustment_type"]).to eq(tag_adjustment.adjustment_type)
    end
  end
end
