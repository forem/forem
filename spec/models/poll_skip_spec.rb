require "rails_helper"

RSpec.describe PollSkip, type: :model do
  let(:article) { create(:article, featured: true) }
  let(:user) { create(:user) }
  let(:poll) { create(:poll, article: article) }

  describe "validations" do
    context "when checking against poll" do
      before do
        create(:poll_skip, user: user, poll: poll)
      end

      it "is unique across poll and user" do
        expect(build(:poll_skip, user: user, poll: poll)).not_to be_valid
      end

      it "is valid if it belongs to the same user but to a different poll" do
        second_poll = create(:poll, article: article)
        expect(build(:poll_skip, user: user, poll: second_poll)).to be_valid
      end
    end

    it "is unique across user and poll votes for the poll" do
      create(:poll_vote, user: user, poll: poll, poll_option: poll.poll_options.last)
      expect(build(:poll_skip, user: user, poll: poll)).not_to be_valid
    end
  end
end
