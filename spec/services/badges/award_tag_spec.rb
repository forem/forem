require "rails_helper"

RSpec.describe Badges::AwardTag, type: :service do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:third_user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:second_article) { create(:article, user_id: second_user.id) }
  let(:third_article) { create(:article, user_id: third_user.id) }
  let(:badge) { create(:badge) }
  let(:tag) { create(:tag, badge_id: badge.id) }

  it "awards badge if qualifying article by score and tagged appropriately" do
    article.update_columns(cached_tag_list: tag.name, score: 101)
    described_class.call
    expect(user.badge_achievements.size).to eq(1)
    expect(user.badge_achievements.last.badge_id).to eq(badge.id)
  end

  it "renders html for message" do
    article.update_columns(cached_tag_list: tag.name, score: 101)
    described_class.call
    expect(user.badge_achievements.size).to eq(1)
    expect(user.badge_achievements.last.rewarding_context_message).to include("<a ")
    expect(user.badge_achievements.last.rewarding_context_message).to include(ApplicationConfig["APP_DOMAIN"])
    expect(user.badge_achievements.last.rewarding_context_message).to include(article.title)
    expect(user.badge_achievements.last.rewarding_context_message).to include(article.path)
  end

  it "does not award badge if qualifying article by score but not tagged appropriately" do
    article.update_columns(cached_tag_list: "differenttag", score: 101)
    described_class.call
    expect(user.badge_achievements.size).to eq(0)
  end

  it "does not award badge if qualifying article by score but not from past week" do
    article.update_columns(published_at: 8.days.ago, cached_tag_list: tag.name, score: 333)
    described_class.call
    expect(user.badge_achievements.size).to eq(0)
  end

  it "does not award badge if tagged appropriately but not published" do
    article.update_columns(cached_tag_list: tag.name, score: 101, published: false)
    described_class.call
    expect(user.badge_achievements.size).to eq(0)
  end

  it "does not award badge to user who has previously won" do
    article.update_columns(cached_tag_list: tag.name, score: 201)
    second_article.update_columns(cached_tag_list: tag.name, score: 150)
    third_article.update_columns(cached_tag_list: tag.name, score: 120)
    described_class.call
    expect(user.reload.badge_achievements.size).to eq(1)
    expect(second_user.reload.badge_achievements.size).to eq(0)
    described_class.call
    expect(user.reload.badge_achievements.size).to eq(1)
    expect(second_user.reload.badge_achievements.size).to eq(1)
    expect(third_user.reload.badge_achievements.size).to eq(0)
    described_class.call
    expect(user.reload.badge_achievements.size).to eq(1)
    expect(second_user.reload.badge_achievements.size).to eq(1)
    expect(third_user.reload.badge_achievements.size).to eq(1)
  end
end
