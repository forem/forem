require "rails_helper"

RSpec.describe CommentObserver, type: :observer do
  let(:user) { create(:user) }
  let(:article) { create(:article) }

  before do
    allow(SlackBot).to receive(:ping).and_return(true)
  end

  it "pings slack if user with warned role creates a comment" do
    perform_enqueued_jobs do
      user.add_role :warned
      Comment.observers.enable :comment_observer do
        run_background_jobs_immediately do
          create(:comment, user: user, commentable: article)
        end
      end
    end
    expect(SlackBot).to have_received(:ping).once
  end
end
