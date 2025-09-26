require "rails_helper"

RSpec.describe Survey, type: :model do
  let(:user) { create(:user) }
  let(:survey) { create(:survey, allow_resubmission: true) }
  let(:poll1) { create(:poll, survey: survey, type_of: :single_choice) }
  let(:poll2) { create(:poll, survey: survey, type_of: :text_input) }
  let(:option1) { create(:poll_option, poll: poll1, markdown: "Option 1") }

  describe "#completed_by_user?" do
    context "when user has not responded to any polls" do
      it "returns false" do
        # Ensure polls are created
        expect(poll1).to be_persisted
        expect(poll2).to be_persisted

        expect(survey.completed_by_user?(user)).to be false
      end
    end

    context "when user has responded to some polls but not all" do
      before do
        # Ensure polls are created
        expect(poll1).to be_persisted
        expect(poll2).to be_persisted
        create(:poll_vote, user: user, poll: poll1, poll_option: option1, session_start: 1)
      end

      it "returns false" do
        expect(survey.completed_by_user?(user)).to be false
      end
    end

    context "when user has responded to all polls" do
      before do
        create(:poll_vote, user: user, poll: poll1, poll_option: option1, session_start: 1)
        create(:poll_text_response, user: user, poll: poll2, text_content: "Test response", session_start: 1)
      end

      it "returns true" do
        expect(survey.completed_by_user?(user)).to be true
      end
    end

    context "when user has responded to all polls but in different sessions" do
      before do
        create(:poll_vote, user: user, poll: poll1, poll_option: option1, session_start: 1)
        create(:poll_text_response, user: user, poll: poll2, text_content: "Test response", session_start: 2)
      end

      it "returns false (only counts responses in the same session)" do
        expect(survey.completed_by_user?(user)).to be false
      end
    end

    context "when survey has no polls" do
      let(:survey) { create(:survey, allow_resubmission: true) }

      it "returns true" do
        expect(survey.completed_by_user?(user)).to be true
      end
    end
  end

  describe "#can_user_submit?" do
    context "when allow_resubmission is true" do
      let(:survey) { create(:survey, allow_resubmission: true) }

      it "always returns true" do
        expect(survey.can_user_submit?(user)).to be true
      end

      it "returns true even when user has completed the survey" do
        create(:poll_vote, user: user, poll: poll1, poll_option: option1, session_start: 1)
        create(:poll_text_response, user: user, poll: poll2, text_content: "Test response", session_start: 1)

        expect(survey.can_user_submit?(user)).to be true
      end
    end

    context "when allow_resubmission is false" do
      let(:survey) { create(:survey, allow_resubmission: false) }

      context "when user has not completed the survey" do
        it "returns true" do
          # Ensure polls are created
          expect(poll1).to be_persisted
          expect(poll2).to be_persisted
          expect(survey.can_user_submit?(user)).to be true
        end
      end

      context "when user has completed the survey" do
        before do
          create(:poll_vote, user: user, poll: poll1, poll_option: option1, session_start: 1)
          create(:poll_text_response, user: user, poll: poll2, text_content: "Test response", session_start: 1)
        end

        it "returns false" do
          expect(survey.can_user_submit?(user)).to be false
        end
      end
    end

    context "when user is nil" do
      it "returns true" do
        expect(survey.can_user_submit?(nil)).to be true
      end
    end
  end

  describe "#get_latest_session" do
    context "when user has no responses" do
      it "returns 0" do
        expect(survey.get_latest_session(user)).to eq(0)
      end
    end

    context "when user has responses in multiple sessions" do
      before do
        create(:poll_vote, user: user, poll: poll1, poll_option: option1, session_start: 1)
        create(:poll_vote, user: user, poll: poll1, poll_option: option1, session_start: 5)
        create(:poll_text_response, user: user, poll: poll2, text_content: "Test", session_start: 3)
      end

      it "returns the highest session number" do
        expect(survey.get_latest_session(user)).to eq(5)
      end
    end

    context "when survey has no polls" do
      let(:survey) { create(:survey, allow_resubmission: true) }

      it "returns 0" do
        expect(survey.get_latest_session(user)).to eq(0)
      end
    end
  end

  describe "#generate_new_session" do
    context "when user has no previous sessions" do
      it "returns 1" do
        expect(survey.generate_new_session(user)).to eq(1)
      end
    end

    context "when user has previous sessions" do
      before do
        create(:poll_vote, user: user, poll: poll1, poll_option: option1, session_start: 3)
      end

      it "returns the next session number" do
        expect(survey.generate_new_session(user)).to eq(4)
      end
    end
  end
end
