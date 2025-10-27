require "rails_helper"

RSpec.describe "Billboard Survey Exclusion", type: :model do
  let(:user) { create(:user) }
  let(:survey) { create(:survey) }
  let(:survey2) { create(:survey) }
  let(:billboard) { create(:billboard, exclude_survey_completions: true, exclude_survey_ids: [survey.id, survey2.id]) }

  describe "#exclude_user_due_to_survey_completion?" do
    context "when exclude_survey_completions is false" do
      let(:billboard) { create(:billboard, exclude_survey_completions: false) }

      it "returns false" do
        expect(billboard.exclude_user_due_to_survey_completion?(user)).to be false
      end
    end

    context "when user is blank" do
      it "returns false" do
        expect(billboard.exclude_user_due_to_survey_completion?(nil)).to be false
      end
    end

    context "when exclude_survey_ids is blank" do
      let(:billboard) { create(:billboard, exclude_survey_completions: true, exclude_survey_ids: []) }

      it "returns false" do
        expect(billboard.exclude_user_due_to_survey_completion?(user)).to be false
      end
    end

    context "when user has completed one of the excluded surveys" do
      before do
        SurveyCompletion.mark_completed!(user: user, survey: survey)
      end

      it "returns true" do
        expect(billboard.exclude_user_due_to_survey_completion?(user)).to be true
      end
    end

    context "when user has completed all of the excluded surveys" do
      before do
        SurveyCompletion.mark_completed!(user: user, survey: survey)
        SurveyCompletion.mark_completed!(user: user, survey: survey2)
      end

      it "returns true" do
        expect(billboard.exclude_user_due_to_survey_completion?(user)).to be true
      end
    end

    context "when user has not completed any of the excluded surveys" do
      it "returns false" do
        expect(billboard.exclude_user_due_to_survey_completion?(user)).to be false
      end
    end
  end

  describe "#exclude_survey_ids=" do
    it "handles comma-separated string input" do
      billboard = create(:billboard)
      billboard.exclude_survey_ids = "1,2,3"
      expect(billboard.exclude_survey_ids).to eq([1, 2, 3])
    end

    it "handles array input" do
      billboard = create(:billboard)
      billboard.exclude_survey_ids = [1, 2, 3]
      expect(billboard.exclude_survey_ids).to eq([1, 2, 3])
    end

    it "filters out blank values" do
      billboard = create(:billboard)
      billboard.exclude_survey_ids = "1,,3,"
      expect(billboard.exclude_survey_ids).to eq([1, 3])
    end
  end
end
