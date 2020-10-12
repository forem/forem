require "rails_helper"

RSpec.describe "BufferUpdates", type: :request do
  let(:user) { create(:user) }
  let(:mod_user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:mod_article) { create(:article, user_id: mod_user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable: article) }

  context "when trusted user is logged in" do
    before do
      sign_in mod_user
      mod_user.add_role(:trusted)
    end

    it "creates buffer update for tweet if tweet params are passed" do
      post "/buffer_updates",
           params:
           { buffer_update: { body_text: "This is the text!!!!", tag_id: "javascript", article_id: article.id } }
      expect(BufferUpdate.all.size).to eq(2)
      expect(BufferUpdate.last.body_text).to start_with("This is the text!!!!")
      expect(BufferUpdate.last.status).to eq("pending")
    end

    it "creates buffer update with link" do
      post "/buffer_updates",
           params:
           { buffer_update: { body_text: "This is the text!!!!", tag_id: "javascript", article_id: article.id } }
      expect(BufferUpdate.first.body_text).to include(article.path)
    end

    it "creates buffer hashtag" do
      SiteConfig.twitter_hashtag = "#DEVCommunity"
      post "/buffer_updates",
           params:
           { buffer_update: { body_text: "This is the text!!!!", tag_id: "javascript", article_id: article.id } }
      expect(BufferUpdate.first.body_text).to include(SiteConfig.twitter_hashtag.to_s)
    end

    it "creates satellite and Facebook buffer" do
      article.update_column(:cached_tag_list, "ruby, rails, meta")
      create(:tag, name: "rails")
      tag = create(:tag, buffer_profile_id_code: "placeholder", name: "ruby")
      post "/buffer_updates",
           params:
           { buffer_update: { body_text: "This is the text!!!!", tag_id: "javascript", article_id: article.id } }
      expect(BufferUpdate.all.size).to eq(3)
      expect(BufferUpdate.second.tag_id).to eq(tag.id)
      expect(BufferUpdate.last.social_service_name).to eq("facebook")
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
             { buffer_update: { body_text: "This is the text!!!!", tag_id: "javascript", article_id: mod_article.id } }
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    it "accepts buffer update from author of article" do
      post "/buffer_updates",
           params:
           { buffer_update: { body_text: "This is the text!!!!", tag_id: "javascript", article_id: article.id } }
      expect(BufferUpdate.first.body_text).to include(article.path)
    end
  end
end
