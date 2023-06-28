require "rails_helper"

RSpec.describe TagAdjustmentUpdateService, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, tags: tag.name) }
  let(:tag) { create(:tag) }

  def create_tag_adjustment
    TagAdjustmentCreationService.new(
      user,
      adjustment_type: "removal",
      status: "committed",
      tag_name: tag.name,
      article_id: article.id,
    )
  end

  before do
    user.add_role(:tag_moderator, tag)
  end

  it "creates tag adjustment" do
    tag_adjustment = create_tag_adjustment.tag_adjustment
    tag_adjustment.save
    described_class.new(tag_adjustment, status: "resolved").update

    expect(tag_adjustment).to be_valid
    expect(tag_adjustment.tag_id).to eq(tag.id)
    expect(tag_adjustment.status).to eq("resolved")
  end
end
