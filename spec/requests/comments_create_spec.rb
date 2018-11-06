require "rails_helper"

RSpec.describe "CommentsCreate", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  before do
    sign_in user
  end

  context "when an ordinary comment is created with proper params" do
    before do
      allow(SlackBot).to receive(:ping).and_return(true)
      new_body = "NEW BODY #{rand(100)}"
      post "/comments", params: {
        comment: { body_markdown: new_body, commentable_id: article.id, commentable_type: "Article" }
      }
    end

    it "creates comment" do
      expect(Comment.last.user_id).to eq(user.id)
    end

    it "pings slack if user has warned role" do
      user.add_role :warned
      expect(SlackBot).to have_received(:ping)
    end
  end
end
