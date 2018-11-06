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
    end

    def create_comment
      new_body = "NEW BODY #{rand(100)}"
      post "/comments", params: {
        comment: { body_markdown: new_body, commentable_id: article.id, commentable_type: "Article" }
      }
    end

    it "creates comment" do
      create_comment
      expect(Comment.last.user_id).to eq(user.id)
    end

    it "creates comment and pings slack if user has warned role" do
      user.add_role :warned
      create_comment
      expect(SlackBot).to have_received(:ping)
    end
  end
end
