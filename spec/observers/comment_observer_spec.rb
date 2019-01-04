require "rails_helper"

RSpec.describe CommentObserver, type: :observer do
  let(:user) { create(:user) }
  let(:article) { create(:article) }

  before do
    allow(SlackBot).to receive(:ping).and_return(true)
  end

  it "pings slack if user with warned role creates a comment" do
    user.add_role :warned
    Comment.observers.enable :comment_observer do
      create(:comment, user_id: user.id, commentable_id: article.id)
    end
    expect(SlackBot).to have_received(:ping)
  end
end
