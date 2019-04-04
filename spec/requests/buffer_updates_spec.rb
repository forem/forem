require "rails_helper"

RSpec.describe "BufferUpdates", type: :request do
  let(:user) { create(:user) }
  let(:mod_user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable_id: article.id) }

  context "when trusted user is logged in" do
    before do
      sign_in mod_user
      mod_user.add_role(:trusted)
    end

    it "creates buffer update for tweet if tweet params are passed" do
      post "/buffer_updates",
        params:
        { buffer_update: { body_text: "This is the text!!!!", tag_id: "javascript", article_id: article.id } }
      expect(BufferUpdate.all.size).to eq(1)
      expect(BufferUpdate.last.body_text).to eq("This is the text!!!!")
      expect(BufferUpdate.last.status).to eq("pending")
    end
  end

  context "when non-trusted user is logged in" do
    before do
      sign_in user
      mod_user.add_role(:trusted)
    end

    it "rejects buffer update for non-trusted user" do
      expect do
        post "/buffer_updates",
        params:
        { buffer_update: { body_text: "This is the text!!!!", tag_id: "javascript", article_id: article.id } }
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  # it "updates last buffered at" do
  #   post "/internal/buffer_updates",
  #     params:
  #     { social_channel: "main_twitter", article_id: article.id, tweet: "Hello this is a test" }
  #   expect(article.reload.last_buffered).not_to eq(nil)
  # end

  # it "updates last buffered at with satellite buffer" do
  #   post "/internal/buffer_updates",
  #     params:
  #     { social_channel: "satellite_twitter", article_id: article.id, tweet: "Hello this is a test" }
  #   expect(article.reload.last_buffered).not_to eq(nil)
  # end

  # it "updates last facebook buffered at" do
  #   post "/internal/buffer_updates",
  #     params:
  #     { social_channel: "facebook", article_id: article.id, tweet: "Hello this is a test" }
  #   expect(article.reload.facebook_last_buffered).not_to eq(nil)
  # end
end
