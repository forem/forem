require "rails_helper"

RSpec.describe "ArticlesUpdate", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  before do
    sign_in user
  end

  it "updates ordinary article with proper params" do
    new_title = "NEW TITLE #{rand(100)}"
    put "/articles/#{article.id}", params: {
      article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" }
    }
    expect(Article.last.title).to eq(new_title)
  end

  it "updates article with front matter params" do
    put "/articles/#{article.id}", params: {
      article: {
        title: "hello",
        body_markdown: "---\ntitle: hey hey hahuu\npublished: false\n---\nYo ho ho#{rand(100)}",
        tag_list: "yo"
      }
    }
    expect(Article.last.edited_at).to be > 5.seconds.ago
    expect(Article.last.title).to eq("hey hey hahuu")
  end
end
