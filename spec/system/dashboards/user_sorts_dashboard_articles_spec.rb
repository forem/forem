require "rails_helper"

RSpec.describe "Sorting Dashboard Articles", type: :system, js: true do
  let(:user) { create(:user) }
  let(:article1) do
    create(:article, user_id: user.id, published_at: 10.minutes.ago, created_at: 1.day.ago, public_reactions_count: 5,
                     page_views_count: 0, comments_count: 100)
  end
  let(:article2) do
    create(:article, user_id: user.id, published_at: 1.minute.ago, created_at: 2.days.ago, public_reactions_count: 1,
                     page_views_count: 10, comments_count: 0)
  end
  let(:article3) do
    create(:article, user_id: user.id, published_at: 5.minutes.ago, created_at: 3.days.ago, public_reactions_count: 0,
                     page_views_count: 1000, comments_count: 50)
  end
  let(:articles) { [article1, article2, article3] }

  let(:article_with_comments_count_of) do
    ->(target_count) { articles.detect { |article| article.comments_count == target_count } }
  end

  let(:test_article_order) do
    lambda do |url, expected_article_array|
      visit url
      comments_counts_on_page = page.all(".spec__dashboard-story .spec__comments-count").map { |e| e.text.to_i }
      articles_on_page = comments_counts_on_page.map do |count|
        article_with_comments_count_of.call(count)
      end
      expect(articles_on_page).to eq(expected_article_array)
    end
  end

  before do
    article1
    article2
    article3
    sign_in user
  end

  it "shows articles sorted by default in created_at DESC" do
    test_article_order.call("/dashboard", [article1, article2, article3])
  end

  it "shows articles sorted by created_at ASC" do
    test_article_order.call("/dashboard?sort=creation-asc", [article3, article2, article1])
  end

  it "shows articles sorted by comments_count DESC" do
    test_article_order.call("/dashboard?sort=comments-desc", [article1, article3, article2])
  end

  it "shows articles sorted by page_views_count ASC" do
    test_article_order.call("/dashboard?sort=views-asc", [article1, article2, article3])
  end

  it "shows articles sorted by public_reactions_count ASC" do
    test_article_order.call("/dashboard?sort=reactions-asc", [article3, article2, article1])
  end

  it "shows articles sorted by published_at DESC" do
    test_article_order.call("/dashboard?sort=published-desc", [article2, article3, article1])
  end
end
