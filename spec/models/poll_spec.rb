require "rails_helper"

RSpec.describe Poll do
  let(:article) { create(:article, featured: true) }

  describe "validations" do
    let(:poll) { build(:poll, article: article) }

    describe "builtin validations" do
      subject { poll }

      it { is_expected.to have_many(:poll_options).dependent(:delete_all) }
      it { is_expected.to have_many(:poll_skips).dependent(:delete_all) }
      it { is_expected.to have_many(:poll_votes).dependent(:delete_all) }

      it { is_expected.to validate_length_of(:poll_options_input_array).is_at_least(2).is_at_most(15) }

      it { is_expected.to validate_presence_of(:poll_options_count) }
      it { is_expected.to validate_presence_of(:poll_options_input_array) }
      it { is_expected.to validate_presence_of(:poll_skips_count) }
      it { is_expected.to validate_presence_of(:poll_votes_count) }
      it { is_expected.to validate_presence_of(:prompt_markdown) }
    end

    describe "#prompt_markdown" do
      it "is valid up to 128 chars" do
        poll.prompt_markdown = "x" * 128
        expect(poll).to be_valid
      end

      it "is not valid with more than 128 chars" do
        poll.prompt_markdown = "x" * 129
        expect(poll).not_to be_valid
      end
    end
  end

  describe "#vote_previously_recorded_for?" do
    subject(:registered) { poll.vote_previously_recorded_for?(user_id: user.id) }

    let(:poll) {  create(:poll) }
    let(:user) {  create(:user) }

    context "when user has existing poll_votes" do
      before do
        create(:poll_vote, poll: poll, user: user)
      end

      it { is_expected.to be_truthy }
    end

    context "when user has existing poll_skips" do
      before do
        create(:poll_skip, poll: poll, user: user)
      end

      it { is_expected.to be_truthy }
    end

    context "when user has no poll_skips nor poll votes" do
      it { is_expected.to be_falsey }
    end
  end

  context "when callbacks are triggered after create" do
    it "creates options from input" do
      options = %w[hello goodbye heyheyhey]
      expect do
        create(:poll, article: article, poll_options_input_array: options)
      end.to change(PollOption, :count).by(options.size)
    end
  end
end
