require "rails_helper"

RSpec.describe PollVote, type: :model do
  let(:article) { create(:article, featured: true) }
  let(:user) { create(:user) }
  let(:poll) { create(:poll, article_id: article.id) }

  it "limits one vote per user per poll" do
    create(:poll_vote, poll_option_id: poll.poll_options.last.id, user_id: user.id)
    PollVote.create(poll_option_id: poll.poll_options.first.id, user_id: user.id)
    PollVote.create(poll_option_id: poll.poll_options.last.id, user_id: user.id)
    expect(user.poll_votes.size).to eq(1)
  end

  it "allows one vote per user across multipel polls" do
    second_pull = create(:poll, article_id: article.id)
    create(:poll_vote, poll_option_id: poll.poll_options.last.id, user_id: user.id)
    create(:poll_vote, poll_option_id: second_pull.poll_options.last.id, user_id: user.id)
    expect(user.poll_votes.size).to eq(2)
  end

  it "allows multiple people to vote in one poll" do
    second_user = create(:user)
    create(:poll_vote, poll_option_id: poll.poll_options.last.id, user_id: user.id)
    create(:poll_vote, poll_option_id: poll.poll_options.last.id, user_id: second_user.id)
    expect(user.poll_votes.size).to eq(1)
    expect(second_user.poll_votes.size).to eq(1)
  end

  it "disallows a user to skip poll after voting" do
    create(:poll_vote, poll_option_id: poll.poll_options.last.id, user_id: user.id)
    PollSkip.create(poll_id: poll.id, user_id: user.id)
    expect(user.poll_skips.size).to eq(0)
  end

  it "disallows a vote after skipping" do
    PollSkip.create(poll_id: poll.id, user_id: user.id)
    PollVote.create(poll_option_id: poll.poll_options.last.id, user_id: user.id)
    expect(user.poll_votes.size).to eq(0)
  end
end
