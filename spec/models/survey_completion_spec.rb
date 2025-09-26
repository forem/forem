require "rails_helper"

RSpec.describe SurveyCompletion, type: :model do
  let(:user) { create(:user) }
  let(:survey) { create(:survey) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:survey) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:completed_at) }

    it "validates uniqueness of user_id scoped to survey_id" do
      create(:survey_completion, user: user, survey: survey, completed_at: Time.current)
      duplicate = build(:survey_completion, user: user, survey: survey, completed_at: Time.current)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("has already been taken")
    end
  end

  describe ".mark_completed!" do
    it "creates a new completion record" do
      expect do
        SurveyCompletion.mark_completed!(user: user, survey: survey)
      end.to change(SurveyCompletion, :count).by(1)
    end

    it "does not create duplicate completion records" do
      SurveyCompletion.mark_completed!(user: user, survey: survey)

      expect do
        SurveyCompletion.mark_completed!(user: user, survey: survey)
      end.not_to change(SurveyCompletion, :count)
    end

    it "sets completed_at to current time" do
      completion = SurveyCompletion.mark_completed!(user: user, survey: survey)
      expect(completion.completed_at).to be_within(1.second).of(Time.current)
    end
  end

  describe ".user_completed_any?" do
    let(:survey2) { create(:survey) }

    it "returns true if user has completed any of the specified surveys" do
      SurveyCompletion.mark_completed!(user: user, survey: survey)

      expect(SurveyCompletion.user_completed_any?(user: user, survey_ids: [survey.id, survey2.id])).to be true
    end

    it "returns false if user has not completed any of the specified surveys" do
      expect(SurveyCompletion.user_completed_any?(user: user, survey_ids: [survey.id, survey2.id])).to be false
    end

    it "returns false if user is blank" do
      expect(SurveyCompletion.user_completed_any?(user: nil, survey_ids: [survey.id])).to be false
    end

    it "returns false if survey_ids is blank" do
      expect(SurveyCompletion.user_completed_any?(user: user, survey_ids: [])).to be false
    end
  end

  describe ".completed_survey_ids_for_user" do
    let(:survey2) { create(:survey) }

    it "returns survey IDs that the user has completed" do
      SurveyCompletion.mark_completed!(user: user, survey: survey)
      SurveyCompletion.mark_completed!(user: user, survey: survey2)

      expect(SurveyCompletion.completed_survey_ids_for_user(user)).to contain_exactly(survey.id, survey2.id)
    end

    it "returns empty array if user has not completed any surveys" do
      expect(SurveyCompletion.completed_survey_ids_for_user(user)).to eq([])
    end

    it "returns empty array if user is blank" do
      expect(SurveyCompletion.completed_survey_ids_for_user(nil)).to eq([])
    end
  end
end
