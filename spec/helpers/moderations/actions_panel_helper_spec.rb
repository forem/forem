require "rails_helper"

describe Moderations::ActionsPanelHelper do
  describe "#last_adjusted_by_admin?" do
    let(:tag1) { create(:tag) }
    let(:tag2) { create(:tag, name: "tag2") }

    let(:admin) { create(:user, :admin) }
    let(:user) { create(:user) }

    let(:article) { create(:article, tags: "tag2") }

    it "returns false if the last adjustment was made by a non-admin" do
      user.add_role(:tag_moderator, tag2)
      create(:tag_adjustment, article: article, tag_id: tag2.id, tag_name: tag2.name, user: user,
                              status: "committed", adjustment_type: "removal")
      expect(helper.last_adjusted_by_admin?(article, tag2, "removal")).to be(false)
    end

    it "returns true if the last adjustment was made by any admin" do
      create(:tag_adjustment, article: article, tag_id: tag1.id, tag_name: tag1.name, user: admin,
                              status: "committed", adjustment_type: "addition")
      expect(helper.last_adjusted_by_admin?(article, tag1, "addition")).to be(true)
    end
  end
end
