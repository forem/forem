require "rails_helper"

RSpec.describe TagAdjustmentUpdateService do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:tag) { create(:tag) }

  before do
    user.add_role(:tag_moderator, tag)
    @tag_adjustment = TagAdjustmentCreationService.new(
      user,
      {
        adjustment_type: "removal",
        status: "committed",
        tag_name: tag.name,
        article_id: article.id
      }
    ).create
  end

  xit "creates tag adjustment" do
    described_class.new(@tag_adjustment, {status: "resolved"}).update
    expect(@tag_adjustment).to be_valid
    expect(@tag_adjustment.tag_id).to eq(tag.id)
    expect(@tag_adjustment.status).to eq("resolved")
  end

  xit "updates notification" do
    described_class.new(@tag_adjustment, {status: "resolved"}).update
    expect(Notification.last.user_id).to eq(article.user_id)
    expect(Notification.last.json_data["status"]).to eq("resolved")
  end
end
