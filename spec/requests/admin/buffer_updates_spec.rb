require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/buffer_updates", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { build_stubbed(:comment, user_id: user.id, commentable: article) }

  it_behaves_like "an InternalPolicy dependant request", BufferUpdate do
    let(:request) { post "/admin/buffer_updates" }
  end

  describe "POST /admin/buffer_updates" do
    before do
      user.add_role(:super_admin)
      sign_in user
    end

    it "creates buffer update for tweet if tweet params are passed" do
      post "/admin/buffer_updates",
           params:
           { social_channel: "main_twitter", article_id: article.id, tweet: "Hello this is a test" }
      expect(BufferUpdate.all.size).to eq(1)
      post "/admin/buffer_updates",
           params: { social_channel: "main_twitter", article_id: article.id, tweet: "Hello this is a test!" }
      expect(BufferUpdate.all.size).to eq(2)
      expect(BufferUpdate.last.article_id).to eq(article.id)
    end

    it "updates last buffered at" do
      post "/admin/buffer_updates",
           params:
           { social_channel: "main_twitter", article_id: article.id, tweet: "Hello this is a test" }
      expect(article.reload.last_buffered).not_to eq(nil)
    end

    it "marks article as featured" do
      post "/admin/buffer_updates",
           params:
           { social_channel: "main_twitter", article_id: article.id, tweet: "Hello this is a test" }
      expect(article.reload.featured).to be true
    end

    it "updates last buffered at with satellite buffer" do
      post "/admin/buffer_updates",
           params:
           { social_channel: "satellite_twitter", article_id: article.id, tweet: "Hello this is a test" }
      expect(article.reload.last_buffered).not_to eq(nil)
    end

    it "updates last facebook buffered at" do
      post "/admin/buffer_updates",
           params:
           { social_channel: "facebook", article_id: article.id, fb_post: "Hello this is a test" }
      expect(article.reload.facebook_last_buffered).not_to eq(nil)
    end
  end

  describe "PUT /admin/buffer_updates" do
    let(:tag) { create(:tag) }
    let(:buffer_update) do
      BufferUpdate.create(article_id: article.id,
                          composer_user_id: user.id,
                          body_text: "This is text - #{rand(100)}",
                          social_service_name: "twitter",
                          tag_id: tag.id,
                          status: "pending")
    end

    before do
      sign_in user
      user.add_role(:super_admin)
    end

    it "sends to buffer" do
      put "/admin/buffer_updates/#{buffer_update.id}", params: {
        status: "confirmed", body_text: "test"
      }
      expect(buffer_update.reload.buffer_response).not_to eq(nil)
      expect(buffer_update.reload.status).to eq("confirmed")
      expect(buffer_update.reload.approver_user_id).to eq(user.id)
    end
  end
end
