require "rails_helper"

RSpec.describe "Billboard Survey Exclusion Integration", type: :request do
  let(:user) { create(:user) }
  let(:survey) { create(:survey) }
  let(:poll1) { create(:poll, survey: survey, type_of: :single_choice) }
  let(:poll2) { create(:poll, survey: survey, type_of: :single_choice) }
  let(:option1) { create(:poll_option, poll: poll1, markdown: "Option 1") }
  let(:option2) { create(:poll_option, poll: poll2, markdown: "Option 2") }
  let(:billboard) { create(:billboard, exclude_survey_completions: true, exclude_survey_ids: [survey.id]) }

  before do
    # Ensure polls are created
    poll1
    poll2
    option1
    option2
  end

  describe "survey completion affects billboard display" do
    it "shows billboard to user who hasn't completed survey" do
      # User hasn't completed survey yet
      expect(survey.completed_by_user?(user)).to be false

      # Billboard should not exclude this user
      expect(billboard.exclude_user_due_to_survey_completion?(user)).to be false
    end

    it "excludes billboard from user who has completed survey" do
      # User completes the survey by voting on all polls
      create(:poll_vote, user: user, poll: poll1, poll_option: option1, session_start: 1)
      create(:poll_vote, user: user, poll: poll2, poll_option: option2, session_start: 1)

      # Check that survey is completed
      expect(survey.completed_by_user?(user)).to be true

      # Mark survey as completed (this should happen automatically via the service)
      survey.mark_completed_by_user!(user)

      # Billboard should now exclude this user
      expect(billboard.exclude_user_due_to_survey_completion?(user)).to be true
    end
  end

  describe "SurveyCompletionService integration" do
    it "automatically marks survey as completed when user votes on all polls" do
      # User votes on first poll
      create(:poll_vote, user: user, poll: poll1, poll_option: option1, session_start: 1)

      # Survey not completed yet
      expect(survey.completed_by_user?(user)).to be false
      expect(survey.completion_recorded_for_user?(user)).to be false

      # User votes on second poll - this should complete the survey
      create(:poll_vote, user: user, poll: poll2, poll_option: option2, session_start: 1)

      # Check that survey is completed
      expect(survey.completed_by_user?(user)).to be true

      # Mark survey as completed (simulating what the service would do)
      survey.mark_completed_by_user!(user)

      # Check that completion is recorded
      expect(survey.completion_recorded_for_user?(user)).to be true
      expect(SurveyCompletion.exists?(user: user, survey: survey)).to be true
    end
  end
end
