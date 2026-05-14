require "rails_helper"

RSpec.describe "Admin::Surveys", type: :request do
  let(:admin) { create(:user) }

  before do
    admin.add_role(:super_admin)
    login_as admin
  end

  describe "GET /admin/content_manager/surveys" do
    it "renders the index page" do
      get admin_surveys_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/content_manager/surveys" do
    context "with valid parameters" do
      let(:survey_params) do
        {
          survey: {
            title: "Test Survey",
            active: true,
            daily_email_distributions: 50,
            extra_email_context_paragraph: "Please tell us what you think!",
            polls_attributes: [
              {
                prompt_markdown: "What is your favorite color?",
                type_of: "single_choice",
                position: 0,
                poll_options_attributes: [
                  { markdown: "Red", position: 0 },
                  { markdown: "Blue", position: 1 }
                ]
              }
            ]
          }
        }
      end

      it "creates a new survey" do
        expect {
          post admin_surveys_path, params: survey_params
        }.to change(Survey, :count).by(1).and change(Poll, :count).by(1).and change(PollOption, :count).by(2)
        
        survey = Survey.last
        expect(survey.daily_email_distributions).to eq(50)
        expect(survey.extra_email_context_paragraph).to eq("Please tell us what you think!")

        expect(response).to redirect_to(admin_surveys_path)
        follow_redirect!
        expect(response.body).to include("Survey has been created!")
      end

      it "creates a scale poll and generates options automatically" do
        scale_params = {
          survey: {
            title: "Scale Survey",
            polls_attributes: [
              {
                prompt_markdown: "Rate this",
                type_of: "scale",
                scale_min: 1,
                scale_max: 3
              }
            ]
          }
        }
        expect {
          post admin_surveys_path, params: scale_params
        }.to change(PollOption, :count).by(3)
        
        poll = Poll.last
        expect(poll.poll_options.pluck(:markdown)).to eq(%w[1 2 3])
      end
    end

    context "with invalid parameters" do
      it "does not create a survey" do
        expect {
          post admin_surveys_path, params: { survey: { title: "" } }
        }.not_to change(Survey, :count)
        expect(response.body).to include("can&#39;t be blank")
      end
    end
  end

  describe "PATCH /admin/content_manager/surveys/:id" do
    let(:survey) { create(:survey) }
    let!(:poll) { create(:poll, survey: survey) }

    it "updates the survey" do
      patch admin_survey_path(survey), params: { survey: { title: "Updated Title" } }
      expect(survey.reload.title).to eq("Updated Title")
      expect(response).to redirect_to(admin_surveys_path)
    end

    it "can delete a poll via nested attributes" do
      expect {
        patch admin_survey_path(survey), params: {
          survey: {
            polls_attributes: [{ id: poll.id, _destroy: "1" }]
          }
        }
      }.to change(Poll, :count).by(-1)
    end
  end

  describe "DELETE /admin/content_manager/surveys/:id" do
    let!(:survey) { create(:survey) }

    it "deletes the survey" do
      expect {
        delete admin_survey_path(survey)
      }.to change(Survey, :count).by(-1)
      expect(response).to redirect_to(admin_surveys_path)
    end
  end
end
