require "rails_helper"

RSpec.describe Badges::AwardBelovedComment, type: :service do
  let!(:comment) { create(:comment, commentable: create(:article)) }

  before do
    create(:badge, title: "Beloved comment", slug: "beloved-comment")
  end

  describe ".call" do
    it "awards beloved comment to folks who have a qualifying comment" do
      comment.update(public_reactions_count: 25)
      expect do
        described_class.call
      end.to change(BadgeAchievement, :count).by(1)
    end

    it "does not reward beloved comment to non-qualifying comment" do
      expect do
        described_class.call
      end.not_to change(BadgeAchievement, :count)
    end
  end
end
