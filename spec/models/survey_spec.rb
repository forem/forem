require "rails_helper"

RSpec.describe Survey, type: :model do
  # has many polls association
  it { is_expected.to have_many(:polls).dependent(:nullify) }

  describe "#completed_by_user?" do
    let(:user) { create(:user) }
    let(:survey) { create(:survey) }
    let(:poll1) { create(:poll, survey: survey) }
    let(:poll2) { create(:poll, survey: survey) }

    before do
      # Create poll options for the polls
      create(:poll_option, poll: poll1)
      create(:poll_option, poll: poll2)
    end

    context "when user has not responded to any polls" do
      it "returns false" do
        expect(survey.completed_by_user?(user)).to be false
      end
    end

    context "when user has responded to some polls" do
      before do
        create(:poll_vote, user: user, poll: poll1, session_start: 1)
      end

      it "returns false" do
        expect(survey.completed_by_user?(user)).to be false
      end
    end

    context "when user has responded to all polls in the same session" do
      before do
        create(:poll_vote, user: user, poll: poll1, session_start: 1)
        create(:poll_vote, user: user, poll: poll2, session_start: 1)
      end

      it "returns true" do
        expect(survey.completed_by_user?(user)).to be true
      end
    end

    context "when user has mixed responses (votes, skips, text responses) in the same session" do
      before do
        create(:poll_vote, user: user, poll: poll1, session_start: 1)
        create(:poll_skip, user: user, poll: poll2, session_start: 1)
      end

      it "returns true" do
        expect(survey.completed_by_user?(user)).to be true
      end
    end

    context "when user has responses in different sessions" do
      before do
        create(:poll_vote, user: user, poll: poll1, session_start: 1)
        create(:poll_vote, user: user, poll: poll2, session_start: 2)
      end

      it "returns false (only counts latest session)" do
        expect(survey.completed_by_user?(user)).to be false
      end
    end

    context "when survey has no polls" do
      let(:empty_survey) { create(:survey) }

      it "returns true" do
        expect(empty_survey.completed_by_user?(user)).to be true
      end
    end

    context "when user is nil" do
      it "returns false" do
        expect(survey.completed_by_user?(nil)).to be false
      end
    end
  end

  describe "#can_user_submit?" do
    let(:user) { create(:user) }
    let(:survey) { create(:survey) }

    context "when user is nil" do
      it "returns true" do
        expect(survey.can_user_submit?(nil)).to be true
      end
    end

    context "when allow_resubmission is true" do
      let(:survey) { create(:survey, allow_resubmission: true) }

      it "returns true even if user has completed the survey" do
        # Mock the completed_by_user? method to return true
        allow(survey).to receive(:completed_by_user?).with(user).and_return(true)
        expect(survey.can_user_submit?(user)).to be true
      end
    end

    context "when allow_resubmission is false" do
      let(:survey) { create(:survey, allow_resubmission: false) }

      context "when user has not completed the survey" do
        it "returns true" do
          allow(survey).to receive(:completed_by_user?).with(user).and_return(false)
          expect(survey.can_user_submit?(user)).to be true
        end
      end

      context "when user has completed the survey" do
        it "returns false" do
          allow(survey).to receive(:completed_by_user?).with(user).and_return(true)
          expect(survey.can_user_submit?(user)).to be false
        end
      end
    end
  end

  describe "#get_latest_session" do
    let(:user) { create(:user) }
    let(:survey) { create(:survey) }
    let(:poll) { create(:poll, survey: survey) }

    context "when user has no responses" do
      it "returns 0" do
        expect(survey.get_latest_session(user)).to eq(0)
      end
    end

    context "when user has responses in different sessions" do
      let(:poll2) { create(:poll, survey: survey) }
      let(:poll3) { create(:poll, survey: survey) }

      before do
        create(:poll_vote, user: user, poll: poll, session_start: 1)
        create(:poll_vote, user: user, poll: poll2, session_start: 3)
        create(:poll_skip, user: user, poll: poll3, session_start: 2)
      end

      it "returns the highest session number" do
        expect(survey.get_latest_session(user)).to eq(3)
      end
    end
  end

  describe "#generate_new_session" do
    let(:user) { create(:user) }
    let(:survey) { create(:survey) }
    let(:poll) { create(:poll, survey: survey) }

    context "when user has no responses" do
      it "returns 1" do
        expect(survey.generate_new_session(user)).to eq(1)
      end
    end

    context "when user has responses in session 3" do
      before do
        create(:poll_vote, user: user, poll: poll, session_start: 3)
      end

      it "returns 4" do
        expect(survey.generate_new_session(user)).to eq(4)
      end
    end
  end
end
