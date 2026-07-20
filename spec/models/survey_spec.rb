require "rails_helper"

RSpec.describe Survey, type: :model do
  let(:user) { create(:user) }
  let(:survey) { create(:survey, allow_resubmission: true) }
  let(:poll1) { create(:poll, survey: survey, type_of: :single_choice) }
  let(:poll2) { create(:poll, survey: survey, type_of: :text_input) }
  let(:option1) { create(:poll_option, poll: poll1, markdown: "Option 1") }

  describe "#slug" do
    it "is generated from title on create" do
      survey = create(:survey, title: "My Great Survey")
      expect(survey.slug).to be_present
      expect(survey.slug).to start_with("my-great-survey-")
    end

    it "is not regenerated on update" do
      survey = create(:survey, title: "My Great Survey")
      original_slug = survey.slug
      survey.update(title: "New Title")
      expect(survey.slug).to eq(original_slug)
    end

    it "can be updated manually" do
      survey = create(:survey, title: "My Great Survey")
      survey.update(slug: "custom-slug")
      expect(survey.slug).to eq("custom-slug")
    end

    it "rotates old slugs on update" do
      survey = create(:survey, title: "Original Title")
      slug1 = survey.slug

      survey.update(slug: "slug-2")
      expect(survey.slug).to eq("slug-2")
      expect(survey.old_slug).to eq(slug1)
      expect(survey.old_old_slug).to be_nil

      survey.update(slug: "slug-3")
      expect(survey.slug).to eq("slug-3")
      expect(survey.old_slug).to eq("slug-2")
      expect(survey.old_old_slug).to eq(slug1)
    end

    it "validates uniqueness" do
      create(:survey, slug: "taken-slug")
      survey = build(:survey, slug: "taken-slug")
      expect(survey).not_to be_valid
      expect(survey.errors[:slug]).to include("has already been taken")
    end

    it "allows nil slug" do
      survey = build(:survey, slug: nil)
      expect(survey).to be_valid
    end
  end

  describe "#to_param" do
    it "returns id" do
      survey = create(:survey)
      expect(survey.to_param).to eq(survey.id.to_s)
    end
  end

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

  describe "target features" do
    describe "#target_based?" do
      it "returns true if both target response count and completion date are present" do
        survey = build(:survey, target_response_count: 100, target_completion_date: 5.days.from_now)
        expect(survey.target_based?).to be true
      end

      it "returns false if target response count is zero/nil or completion date is nil" do
        survey1 = build(:survey, target_response_count: 0, target_completion_date: 5.days.from_now)
        survey2 = build(:survey, target_response_count: 100, target_completion_date: nil)
        expect(survey1.target_based?).to be false
        expect(survey2.target_based?).to be false
      end
    end

    describe "validations" do
      it "validates target_response_count is a non-negative integer" do
        survey = build(:survey, target_response_count: -5)
        expect(survey).not_to be_valid
        expect(survey.errors[:target_response_count]).to include("must be greater than or equal to 0")

        survey.target_response_count = 5.5
        expect(survey).not_to be_valid

        survey.target_response_count = 5
        expect(survey).to be_valid
      end

      it "validates target_completion_date is in the future on create/update if changed" do
        survey = build(:survey, target_completion_date: 1.day.ago)
        expect(survey).not_to be_valid
        expect(survey.errors[:target_completion_date]).to include("must be in the future")

        survey = create(:survey, target_completion_date: 2.days.from_now)
        # updating without changing date is valid
        survey.title = "Updated Title"
        expect(survey).to be_valid
      end
    end

    describe "default send rate calculation" do
      it "sets default daily_email_distributions based on target and time remaining" do
        # 100 completions needed over 5 days = 20 completions/day.
        # At 1 completion per 200 sends, rate should be 20 * 200 = 4000.
        survey = create(:survey, target_response_count: 100, target_completion_date: 5.days.from_now, daily_email_distributions: 0)
        expect(survey.daily_email_distributions).to eq(4000)
      end

      it "does not overwrite non-zero daily_email_distributions" do
        survey = create(:survey, target_response_count: 100, target_completion_date: 5.days.from_now, daily_email_distributions: 15)
        expect(survey.daily_email_distributions).to eq(15)
      end
    end
  end
end
