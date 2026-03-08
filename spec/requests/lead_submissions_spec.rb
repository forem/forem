require "rails_helper"

RSpec.describe "LeadSubmissions" do
  let(:organization) { create(:organization) }
  let(:lead_form) { create(:organization_lead_form, organization: organization) }
  let(:user) { create(:user) }

  describe "POST /lead_submissions" do
    context "when signed in" do
      before { sign_in user }

      it "creates a submission with user data snapshot" do
        post "/lead_submissions", params: { organization_lead_form_id: lead_form.id }, as: :json

        expect(response).to have_http_status(:ok)
        parsed = response.parsed_body
        expect(parsed["success"]).to be true

        submission = LeadSubmission.last
        expect(submission.user).to eq(user)
        expect(submission.name).to eq(user.name)
        expect(submission.email).to eq(user.email)
      end

      it "prevents duplicate submissions" do
        create(:lead_submission, organization_lead_form: lead_form, user: user)

        post "/lead_submissions", params: { organization_lead_form_id: lead_form.id }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        parsed = response.parsed_body
        expect(parsed["success"]).to be false
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
      it "returns unauthorized" do
        post "/lead_submissions", params: { organization_lead_form_id: lead_form.id }, as: :json

        expect(response).to have_http_status(:unauthorized).or redirect_to(sign_up_path)
      end
    end
  end
end
