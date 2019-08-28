require "rails_helper"

RSpec.describe PollVote, type: :model do
  let(:article) { create(:article, featured: true) }
  let(:user) { create(:user) }
  let(:poll) { create(:poll, article_id: article.id) }

  it "is not valid as a new object" do
    expect(described_class.new.valid?).to be(false)
  end

  it "limits one vote per user per poll" do
    create(:poll_vote, poll_option_id: poll.poll_options.last.id, user_id: user.id, poll_id: poll.id)
    described_class.create(poll_option_id: poll.poll_options.first.id, user_id: user.id, poll_id: poll.id)
    described_class.create(poll_option_id: poll.poll_options.last.id, user_id: user.id, poll_id: poll.id)
    expect(user.poll_votes.size).to eq(1)
  end

  it "allows one vote per user across multiple polls" do
    second_poll = create(:poll, article_id: article.id)
    create(:poll_vote, poll_option_id: poll.poll_options.last.id, user_id: user.id, poll_id: poll.id)
    create(:poll_vote, poll_option_id: second_poll.poll_options.last.id, user_id: user.id, poll_id: second_poll.id)
    expect(user.reload.poll_votes.size).to eq(2)
  end

  it "allows multiple people to vote in one poll" do
    second_user = create(:user)
    create(:poll_vote, poll_option_id: poll.poll_options.last.id, user_id: user.id, poll_id: poll.id)
    create(:poll_vote, poll_option_id: poll.poll_options.last.id, user_id: second_user.id, poll_id: poll.id)
    expect(user.poll_votes.size).to eq(1)
    expect(second_user.poll_votes.size).to eq(1)
  end

  it "disallows a user to skip poll after voting" do
    create(:poll_vote, poll_option_id: poll.poll_options.last.id, user_id: user.id, poll_id: poll.id)
    PollSkip.create(poll_id: poll.id, user_id: user.id)
    expect(user.poll_skips.size).to eq(0)
  end

  it "disallows a vote after skipping" do
    PollSkip.create(poll_id: poll.id, user_id: user.id)
    described_class.create(poll_option_id: poll.poll_options.last.id, user_id: user.id, poll_id: poll.id)
    expect(user.poll_votes.size).to eq(0)
  end

  it "updates poll voting count after create" do
    create(:poll_vote, poll_option_id: poll.poll_options.last.id, user_id: user.id, poll_id: poll.id)
    expect(poll.reload.poll_votes_count).to eq(1)
    expect(poll.reload.poll_options.last.poll_votes_count).to eq(1)
  end

  it "updates poll voting count after create with accuracy alongside skips" do
    create(:poll_vote, poll_option_id: poll.poll_options.last.id, user_id: user.id, poll_id: poll.id)
    PollSkip.create(poll_id: poll.id, user_id: user.id)
    expect(poll.reload.poll_votes_count).to eq(1)
    expect(poll.reload.poll_options.last.poll_votes_count).to eq(1)
  end
end
