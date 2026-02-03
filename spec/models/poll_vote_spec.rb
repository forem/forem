require "rails_helper"

RSpec.describe PollVote do
  let(:article) { create(:article, featured: true) }
  let(:user) { create(:user) }
  let(:poll) { create(:poll, article_id: article.id) }

  it "is not valid as a new object" do
    expect(described_class.new.valid?).to be(false)
  end

  context "when user has not voted nor skipped the poll" do
    it "is valid" do
      vote = build(:poll_vote, poll_option: poll.poll_options.last, user: user, poll: poll)
      allow(vote.poll).to receive(:vote_previously_recorded_for?).with(user_id: user.id).and_return(false)

      expect(vote).to be_valid
      expect(vote.errors[:base]).to be_empty
    end
  end

  describe "validation rules for different poll types" do
    let(:poll_option1) { poll.poll_options.first }
    let(:poll_option2) { poll.poll_options.second }

    context "with single choice polls" do
      it "allows only one vote per user per poll" do
        create(:poll_vote, poll: poll, poll_option: poll_option1, user: user)
        second_vote = build(:poll_vote, poll: poll, poll_option: poll_option2, user: user)
        
        expect(second_vote).not_to be_valid
        expect(second_vote.errors[:poll_id]).to include("has already been taken")
      end
    end

    context "with multiple choice polls" do
      let(:multiple_choice_poll) { create(:poll, :multiple_choice, article_id: article.id) }
      let(:option1) { multiple_choice_poll.poll_options.first }
      let(:option2) { multiple_choice_poll.poll_options.second }

      it "allows multiple votes from the same user" do
        create(:poll_vote, poll: multiple_choice_poll, poll_option: option1, user: user)
        second_vote = build(:poll_vote, poll: multiple_choice_poll, poll_option: option2, user: user)
        
        expect(second_vote).to be_valid
      end

      it "prevents duplicate votes on the same option" do
        create(:poll_vote, poll: multiple_choice_poll, poll_option: option1, user: user)
        duplicate_vote = build(:poll_vote, poll: multiple_choice_poll, poll_option: option1, user: user)
        
        expect(duplicate_vote).not_to be_valid
        expect(duplicate_vote.errors[:poll_option_id]).to include("has already been taken")
      end
    end

    context "with scale polls" do
      let(:scale_poll) { create(:poll, :scale, article_id: article.id) }
      let(:option1) { scale_poll.poll_options.first }
      let(:option2) { scale_poll.poll_options.second }

      it "allows multiple votes from the same user" do
        create(:poll_vote, poll: scale_poll, poll_option: option1, user: user)
        second_vote = build(:poll_vote, poll: scale_poll, poll_option: option2, user: user)
        
        expect(second_vote).to be_valid
      end

      it "prevents duplicate votes on the same option" do
        create(:poll_vote, poll: scale_poll, poll_option: option1, user: user)
        duplicate_vote = build(:poll_vote, poll: scale_poll, poll_option: option1, user: user)
        
        expect(duplicate_vote).not_to be_valid
        expect(duplicate_vote.errors[:poll_option_id]).to include("has already been taken")
      end
    end
  end
end
