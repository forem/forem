require "rails_helper"

RSpec.describe Favorites::ImpactData, type: :service do
  let(:user_a) { create(:user) }
  let(:user_b) { create(:user) }

  def favorite_article(user, comments_count: 0, public_reactions_count: 0, page_views_count: 0)
    create(:article).tap do |article|
      article.update_columns(
        favorited_by_user_id: user.id, favorited_at: Time.current,
        comments_count: comments_count, public_reactions_count: public_reactions_count,
        page_views_count: page_views_count
      )
    end
  end

  def favorite_comment(user, public_reactions_count: 0)
    create(:comment).tap do |comment|
      comment.update_columns(
        favorited_by_user_id: user.id, favorited_at: Time.current,
        public_reactions_count: public_reactions_count
      )
    end
  end

  it "returns an empty ranking when nothing is favorited" do
    expect(described_class.call).to eq([])
  end

  it "scores article impact as comments + reactions + views" do
    favorite_article(user_a, comments_count: 3, public_reactions_count: 5, page_views_count: 10)

    row = described_class.call.first

    expect(row.user).to eq(user_a)
    expect(row.impact_score).to eq(18)
    expect(row.article_favorites_count).to eq(1)
    expect(row.comment_favorites_count).to eq(0)
    expect(row.favorites_count).to eq(1)
  end

  it "scores comment impact from reactions only" do
    favorite_comment(user_a, public_reactions_count: 4)

    row = described_class.call.first

    expect(row.impact_score).to eq(4)
    expect(row.comment_favorites_count).to eq(1)
  end

  it "combines a user's article and comment favorites" do
    favorite_article(user_a, comments_count: 1, public_reactions_count: 1, page_views_count: 1)
    favorite_comment(user_a, public_reactions_count: 2)

    row = described_class.call.first

    expect(row.impact_score).to eq(5)
    expect(row.favorites_count).to eq(2)
    expect(row.article_favorites_count).to eq(1)
    expect(row.comment_favorites_count).to eq(1)
  end

  it "ranks users by descending impact" do
    favorite_article(user_a, page_views_count: 100)
    favorite_article(user_b, page_views_count: 5)

    expect(described_class.call.map(&:user)).to eq([user_a, user_b])
  end

  it "honors the limit" do
    favorite_article(user_a, page_views_count: 20)
    favorite_article(user_b, page_views_count: 10)

    expect(described_class.call(limit: 1).map(&:user)).to eq([user_a])
  end
end
