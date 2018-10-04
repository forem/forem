require "rails_helper"

RSpec.describe "InternalBufferUpdates", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable_id: article.id) }

  before do
    sign_in user
    user.add_role(:super_admin)
  end

  it "creates buffer update for tweet if tweet params are passed" do
    post "/internal/buffer_updates",
      params:
      { social_channel: "main_twitter", article_id: article.id, tweet: "Hello this is a test" }
    expect(BufferUpdate.all.size).to eq(1)
    post "/internal/buffer_updates",
    params: { social_channel: "main_twitter", article_id: article.id, tweet: "Hello this is a test!" }
    expect(BufferUpdate.all.size).to eq(2)
    expect(BufferUpdate.last.article_id).to eq(article.id)
  end

  it "updates last buffered at" do
    post "/internal/buffer_updates",
      params:
      { social_channel: "main_twitter", article_id: article.id, tweet: "Hello this is a test" }
    expect(article.reload.last_buffered).not_to eq(nil)
  end

  it "updates last buffered at with satellite buffer" do
    post "/internal/buffer_updates",
      params:
      { social_channel: "satellite_twitter", article_id: article.id, tweet: "Hello this is a test" }
    expect(article.reload.last_buffered).not_to eq(nil)
  end

  it "updates last facebook buffered at" do
    post "/internal/buffer_updates",
      params:
      { social_channel: "facebook", article_id: article.id, tweet: "Hello this is a test" }
    expect(article.reload.facebook_last_buffered).not_to eq(nil)
  end
end
