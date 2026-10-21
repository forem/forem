require "rails_helper"

RSpec.describe "ArticlesFeed" do
  let!(:article) { create(:article) }

  it "returns an rss feed with published articles" do
    get "/feed"

    expect(response.body).to include(article.title)
    expect(response.body).to include("<pubDate>#{article.published_at.to_fs(:rfc822)}</pubDate>")
  end

  context "with a user feed" do
    let(:user) { article.user }

    before { create(:article, user: user, tags: "ruby, rails") }

    def article_and_tagging_queries
      queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql]
        queries << sql if sql.match?(/FROM "(articles|taggings|tags)"/) && !payload[:cached]
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
      queries
    end

    it "renders categories with a single articles query and one batched taggings preload" do
      queries = article_and_tagging_queries { get "/feed/#{user.username}" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<category>ruby</category>")
      expect(response.body).to include("<category>rails</category>")
      expect(queries.count { |sql| sql.include?('FROM "articles"') }).to eq(1)
      # tag_list reads taggings (via acts-as-taggable-on custom_contexts), so the preload must stay batched.
      expect(queries.count { |sql| sql.include?('FROM "taggings"') }).to eq(1)
      expect(queries.grep(/FROM "tags"/)).to be_empty
    end

    it "returns not found when the requested page is past the last article" do
      expect { get "/feed/#{user.username}?page=50" }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
