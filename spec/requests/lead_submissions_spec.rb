require "rails_helper"

RSpec.describe "LeadSubmissions" do
  let(:organization) { create(:organization) }
  let(:lead_form) { create(:organization_lead_form, organization: organization) }
  let(:user) { create(:user) }

  describe "GET /lead_submissions/check" do
    before { sign_in user }

    it "requires a signed-in user" do
      sign_out user

      get "/lead_submissions/check", params: { form_ids: lead_form.id }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the current user's submissions in the existing shape and a fresh CSRF token" do
      submission = create(:lead_submission, organization_lead_form: lead_form, user: user)

      get "/lead_submissions/check", params: { form_ids: lead_form.id }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body[lead_form.id.to_s]).to eq(submission.created_at.iso8601)
      expect(response.parsed_body["csrf_token"]).to be_present
      expect(response.parsed_body).not_to have_key("submissions")
    end
  end

  describe "POST /lead_submissions" do
    context "when signed in" do
      before { sign_in user }

      it "creates a submission with user data snapshot and username" do
        post "/lead_submissions", params: { organization_lead_form_id: lead_form.id }, as: :json

        expect(response).to have_http_status(:ok)
        parsed = response.parsed_body
        expect(parsed["success"]).to be true

        submission = LeadSubmission.last
        expect(submission.user).to eq(user)
        expect(submission.name).to eq(user.name)
        expect(submission.email).to eq(user.email)
        expect(submission.username).to eq(user.username)
        expect(parsed["submitted_at"]).to eq(submission.created_at.iso8601)
      end

      it "treats duplicate submissions as successful" do
        existing_submission = create(:lead_submission, organization_lead_form: lead_form, user: user)

        expect do
          post "/lead_submissions", params: { organization_lead_form_id: lead_form.id }, as: :json
        end.not_to change(LeadSubmission, :count)

        expect(response).to have_http_status(:ok)
        parsed = response.parsed_body
        expect(parsed["success"]).to be true
        expect(parsed["submitted_at"]).to eq(existing_submission.created_at.iso8601)
      end

      it "treats duplicate submissions as successful when save returns false due to uniqueness validation" do
        existing_submission = create(:lead_submission, organization_lead_form: lead_form, user: user)

        allow_any_instance_of(LeadSubmission).to receive(:save) do |instance|
          instance.errors.add(:user_id, "has already been taken")
          false
        end

        post "/lead_submissions", params: { organization_lead_form_id: lead_form.id }, as: :json

        expect(response).to have_http_status(:ok)
        parsed = response.parsed_body
        expect(parsed["success"]).to be true
        expect(parsed["submitted_at"]).to eq(existing_submission.created_at.iso8601)
      end

      it "treats duplicate submissions as successful when ActiveRecord::RecordNotUnique is raised" do
        existing_submission = create(:lead_submission, organization_lead_form: lead_form, user: user)

        allow_any_instance_of(LeadSubmission).to receive(:save).and_raise(ActiveRecord::RecordNotUnique.new("Duplicate entry"))

        post "/lead_submissions", params: { organization_lead_form_id: lead_form.id }, as: :json

        expect(response).to have_http_status(:ok)
        parsed = response.parsed_body
        expect(parsed["success"]).to be true
        expect(parsed["submitted_at"]).to eq(existing_submission.created_at.iso8601)
      end

      it "rejects submissions to inactive forms" do
        lead_form.update!(active: false)

        post "/lead_submissions", params: { organization_lead_form_id: lead_form.id }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        parsed = response.parsed_body
        expect(parsed["success"]).to be false
      end

      it "returns 404 for non-existent form" do
        post "/lead_submissions", params: { organization_lead_form_id: 999999 }, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not signed in" do
      it "creates a submission with provided form data" do
        post "/lead_submissions", params: {
          organization_lead_form_id: lead_form.id,
          name: "Anonymous User",
          email: "anon@example.com",
          company: "Some Corp",
          job_title: "Manager"
        }, as: :json

        expect(response).to have_http_status(:ok)
        parsed = response.parsed_body
        expect(parsed["success"]).to be true

        submission = LeadSubmission.last
        expect(submission.user).to be_nil
        expect(submission.username).to be_nil
        expect(submission.name).to eq("Anonymous User")
        expect(submission.email).to eq("anon@example.com")
        expect(submission.company).to eq("Some Corp")
        expect(submission.job_title).to eq("Manager")
      end

      it "requires name and email for anonymous submissions" do
        post "/lead_submissions", params: {
          organization_lead_form_id: lead_form.id,
          name: "",
          email: ""
        }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        parsed = response.parsed_body
        expect(parsed["success"]).to be false
      end

      it "allows duplicate anonymous submissions" do
        2.times do
          post "/lead_submissions", params: {
            organization_lead_form_id: lead_form.id,
            name: "Same Person",
            email: "same@example.com",
            company: "Corp",
            job_title: "Dev"
          }, as: :json

          expect(response).to have_http_status(:ok)
        end

        expect(LeadSubmission.count).to eq(2)
      end
    end
  end
end
