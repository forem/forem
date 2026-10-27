require "rails_helper"

RSpec.describe "ArticlesFeed" do
  let!(:article) { create(:article) }

  it "returns an rss feed with published articles" do
    get "/feed"

    expect(response.body).to include(article.title)
    expect(response.body).to include("<pubDate>#{article.published_at.to_fs(:rfc822)}</pubDate>")
  end

  context "when item descriptions are cached" do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before { allow(Rails).to receive(:cache).and_return(memory_store) }

    it "renders the same description from cache without sanitizing the body again" do
      get "/feed/#{article.user.username}"
      uncached_body = response.body

      allow(Loofah).to receive(:html5_fragment).and_call_original
      get "/feed/#{article.user.username}"

      expect(response.body).to eq(uncached_body)
      expect(Loofah).not_to have_received(:html5_fragment)
    end

    it "re-sanitizes when processed_html changes without touching updated_at" do
      get "/feed/#{article.user.username}"
      article.update_column(:processed_html, "<p>Fresh <em>body</em></p>")

      get "/feed/#{article.user.username}"

      expect(response.body).to include("&lt;p&gt;Fresh &lt;em&gt;body&lt;/em&gt;&lt;/p&gt;")
    end
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

    it "renders categories from cached_tag_list with a single articles query and no taggings query" do
      queries = article_and_tagging_queries { get "/feed/#{user.username}" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<category>ruby</category>")
      expect(response.body).to include("<category>rails</category>")
      expect(queries.count { |sql| sql.include?('FROM "articles"') }).to eq(1)
      expect(queries.grep(/FROM "taggings"/)).to be_empty
      expect(queries.grep(/FROM "tags"/)).to be_empty
    end

    it "returns not found when the requested page is past the last article" do
      expect { get "/feed/#{user.username}?page=50" }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
