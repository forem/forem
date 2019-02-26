require "rails_helper"

RSpec.describe TagAdjustment, type: :model do
  before do
    mod_user.add_role(:tag_moderator, tag)
    admin_user.add_role(:admin)
  end

  let(:article) { create(:article) }
  let(:tag) { create(:tag) }
  let(:admin_user) { create(:user) }
  let(:mod_user) { create(:user) }
  let(:regular_user) { create(:user) }

  it { is_expected.to validate_presence_of(:user_id) }
  it { is_expected.to validate_presence_of(:article_id) }
  it { is_expected.to validate_presence_of(:tag_id) }
  it { is_expected.to validate_presence_of(:tag_name) }
  it { is_expected.to validate_presence_of(:adjustment_type) }
  it { is_expected.to validate_presence_of(:status) }

  describe "privileges" do
    it "allows tag mods to create for their tags" do
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id)
      expect(tag_adjustment).to be_valid
    end
    it "does not allow tag mods to create for other tags" do
      another_tag = create(:tag)
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: another_tag.id)
      expect(tag_adjustment).to be_invalid
    end
    it "allows admins to create for any tags" do
      tag_adjustment = build(:tag_adjustment, user_id: admin_user.id, article_id: article.id, tag_id: tag.id)
      expect(tag_adjustment).to be_valid
    end
    it "does not allow normal users to create for any tags" do
      tag_adjustment = build(:tag_adjustment, user_id: regular_user.id, article_id: article.id, tag_id: tag.id)
      expect(tag_adjustment).to be_invalid
    end
  end

  describe "allowed attribute states" do
    it "allows proper adjustment_types" do
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id, adjustment_type: "removal")
      expect(tag_adjustment).to be_valid
    end
    it "disallows improper adjustment_types" do
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id, adjustment_type: "slushie")
      expect(tag_adjustment).to be_invalid
    end
    it "allows proper status" do
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id, status: "committed")
      expect(tag_adjustment).to be_valid
    end
    it "disallows improper status" do
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id, status: "slushiemonkey")
      expect(tag_adjustment).to be_invalid
    end
  end
end

# t.integer   :user_id
# t.integer   :article_id
# t.integer   :tag_id
# t.string    :tag_name
# t.string    :adjustment_type
# t.string    :status
# t.string    :reason_for_adjustment
