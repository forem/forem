require "rails_helper"

RSpec.describe TagAdjustment do
  before do
    mod_user.add_role(:tag_moderator, tag)
    other_mod.add_role(:tag_moderator, tag)
  end

  let(:article) { create(:article, tags: nil) }
  let(:tag) { create(:tag) }
  let(:admin_user) { create(:user, :admin) }
  let(:other_admin) { create(:user, :admin) }
  let(:super_mod) { create(:user, :super_moderator) }
  let(:mod_user) { create(:user) }
  let(:other_mod) { create(:user) }
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

    it "allows tag mods to create a tag adjustment for a tag that has been adjusted by another tag mod" do
      create(:tag_adjustment, user_id: other_mod.id, article_id: article.id, tag_id: tag.id)

      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id)
      expect(tag_adjustment).to be_valid
    end

    it "does not allow tag mods to create a tag adjustment for other tags" do
      another_tag = create(:tag)
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: another_tag.id)
      expect(tag_adjustment).not_to be_valid
    end

    it "allows admins to create a tag adjustment for any tags" do
      tag_adjustment = build(:tag_adjustment, user_id: admin_user.id, article_id: article.id, tag_id: tag.id)
      expect(tag_adjustment).to be_valid
    end

    it "allows admins and super moderators to create a tag adjustment for a tag that was adjusted by another admin" do
      create(:tag_adjustment, user_id: admin_user.id, article_id: article.id, tag_id: tag.id)

      tag_adjustment = build(:tag_adjustment, user_id: other_admin.id, article_id: article.id, tag_id: tag.id)
      expect(tag_adjustment).to be_valid

      tag_adjustment = build(:tag_adjustment, user_id: super_mod.id, article_id: article.id, tag_id: tag.id)
      expect(tag_adjustment).to be_valid
    end

    it "does not allow normal users to create a tag adjustment for any tags" do
      tag_adjustment = build(:tag_adjustment, user_id: regular_user.id, article_id: article.id, tag_id: tag.id)
      expect(tag_adjustment).not_to be_valid
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
      expect(tag_adjustment).not_to be_valid
    end

    it "allows proper status" do
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id,
                                              status: "committed")
      expect(tag_adjustment).to be_valid
    end

    it "disallows improper status" do
      tag_adjustment = build(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id,
                                              status: "slushiemonkey")
      expect(tag_adjustment).not_to be_valid
    end
  end

  describe "validates article tag_list" do
    it "does not allow addition on articles with 4 tags" do
      article_tags_maxed = create(:article, tags: "ruby, javascript, html, css")
      tag_adjustment = build(:tag_adjustment, user_id: admin_user.id, article_id: article_tags_maxed.id,
                                              tag_id: tag.id, tag_name: tag.name)
      expect(tag_adjustment).not_to be_valid
    end

    it "does not create if removed tag not on tag_list" do
      article = create(:article, tags: tag.name)
      tag_adjustment = build(:tag_adjustment, user_id: admin_user.id, article_id: article.id,
                                              adjustment_type: "removal")
      expect(tag_adjustment).not_to be_valid
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
