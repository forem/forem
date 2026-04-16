require "rails_helper"

RSpec.describe "Chat Articles", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, type_of: :chat) }

  describe "GET /:username/:slug" do
    it "renders the chat layout for chat articles correctly" do
      get "/#{user.username}/#{article.slug}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include('data-controller="chat-polling"')
      expect(response.body).to include('Chat hosted by')
      
      # Should avoid typical full post features
      expect(response.body).not_to include('div class="crayons-article__main"')
    end

    it "renders standard article format when NOT a chat article" do
      normal_article = create(:article, user: user, type_of: :full_post)
      get "/#{user.username}/#{normal_article.slug}"
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('data-controller="chat-polling"')
      expect(response.body).to include('crayons-article__main')
    end
  end

  describe "GET /chat_comments/:article_id" do
    it "successfully polls and renders only chronological top-level and one deep level structure safely" do
      comment1 = create(:comment, commentable: article, user: user, created_at: 2.minutes.ago)
      comment2 = create(:comment, commentable: article, user: user, created_at: 1.minute.ago)
      sub_comment = create(:comment, commentable: article, user: user, parent_id: comment1.id, created_at: 30.seconds.ago)

      # Attempt deep nesting
      _deep_comment = create(:comment, commentable: article, user: user, parent_id: sub_comment.id)

      get chat_comments_path(article)
      expect(response).to have_http_status(:success)
      
      # The raw HTML should loop and render comments
      expect(response.body).to include(comment1.processed_html)
      expect(response.body).to include(comment2.processed_html)
      expect(response.body).to include(sub_comment.processed_html)
      
      # Deep replies natively filtered out mathematically by loop mapping!
      expect(response.body).not_to include(_deep_comment.processed_html)
    end
  end
end
