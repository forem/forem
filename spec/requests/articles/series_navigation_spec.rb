require "rails_helper"

RSpec.describe "Article series navigation" do
  let(:user) { create(:user) }

  [10, 100].each do |paragraph_count|
    it "renders series navigation once for an article with #{paragraph_count} paragraphs" do
      collection = create(:collection, :with_articles, user: user, amount: 6)
      series_article = collection.articles.order(:published_at).third
      series_article.update_column(:body_markdown, "Synthetic paragraph.\n\n" * paragraph_count)
      partial_renders = []
      callback = lambda do |*, payload|
        partial_renders << payload[:identifier] if payload[:identifier].end_with?("articles/_collection.html.erb")
      end

      ActiveSupport::Notifications.subscribed(callback, "render_partial.action_view") do
        get series_article.path
      end

      expect(response).to have_http_status(:ok)
      navigation = Nokogiri::HTML(response.body).css("nav.series-switcher")
      expect(navigation.size).to eq(paragraph_count == 100 ? 2 : 1)
      expect(navigation.map(&:to_html).uniq.size).to eq(1)
      expect(navigation.first.css("a.series-switcher__link--active").size).to eq(2)
      collection.articles.each { |item| expect(navigation.first.to_html).to include(item.path) }
      expect(partial_renders.size).to eq(1)
    end
  end
end
