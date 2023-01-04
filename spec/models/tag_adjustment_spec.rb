require "rails_helper"

RSpec.describe TagAdjustment do
  before do
    mod_user.add_role(:tag_moderator, tag)
    admin_user.add_role(:admin)
  end

  let(:article) { create(:article, tags: nil) }
  let(:tag) { create(:tag) }
  let(:admin_user) { create(:user) }
  let(:mod_user) { create(:user) }
  let(:regular_user) { create(:user) }

  it { is_expected.to validate_presence_of(:tag_name) }
  it { is_expected.to validate_presence_of(:adjustment_type) }
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to have_many(:notifications).dependent(:delete_all) }

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
    it "allows addition adjustment_types" do
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id)
      expect(tag_adjustment).to be_valid
    end

    it "allows removal adjustment_types" do
      article = create(:article, tags: tag.name)
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id,
                                              tag_name: tag.name, adjustment_type: "removal")
      expect(tag_adjustment).to be_valid
    end

    it "disallows improper adjustment_types" do
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id,
                                              adjustment_type: "slushie")
      expect(tag_adjustment).to be_invalid
    end

    it "allows proper status" do
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id,
                                              status: "committed")
      expect(tag_adjustment).to be_valid
    end

    it "disallows improper status" do
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id,
                                              status: "slushiemonkey")
      expect(tag_adjustment).to be_invalid
    end
  end

  describe "validates article tag_list" do
    it "does not allow addition on articles with 4 tags" do
      article_tags_maxed = create(:article, tags: "ruby, javascript, html, css")
      tag_adjustment = build(:tag_adjustment, user_id: admin_user.id, article_id: article_tags_maxed.id,
                                              tag_id: tag.id, tag_name: tag.name)
      expect(tag_adjustment).to be_invalid
    end

    it "does not create if removed tag not on tag_list" do
      article = create(:article, tags: tag.name)
      tag_adjustment = build(:tag_adjustment, user_id: admin_user.id, article_id: article.id,
                                              adjustment_type: "removal")
      expect(tag_adjustment).to be_invalid
    end

    it "ignores case when checking tag_list" do
      news_tag = create(:tag, name: "news", pretty_name: "News")
      article = create(:article, tags: news_tag.name)
      tag_adjustment = build(
        :tag_adjustment,
        user_id: admin_user.id, article_id: article.id, adjustment_type: "removal",
        tag_id: news_tag.id, tag_name: news_tag.pretty_name
      )
      expect(tag_adjustment).to be_valid
    end
  end
end
