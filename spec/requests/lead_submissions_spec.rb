require "rails_helper"

RSpec.describe "LeadSubmissions" do
  let(:organization) { create(:organization) }
  let(:lead_form) { create(:organization_lead_form, organization: organization) }
  let(:user) { create(:user) }

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

      it "rejects anonymous submission when recaptcha fails" do
        allow(Settings::Authentication).to receive(:recaptcha_site_key).and_return("test-site-key")
        allow(Settings::Authentication).to receive(:recaptcha_secret_key).and_return("test-secret-key")

        post "/lead_submissions", params: {
          organization_lead_form_id: lead_form.id,
          name: "Bot User",
          email: "bot@example.com",
          company: "Bot Corp",
          job_title: "Bot"
        }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        parsed = response.parsed_body
        expect(parsed["success"]).to be false
        expect(parsed["error"]).to eq(I18n.t("lead_submissions.recaptcha_failed"))
      end

      it "allows anonymous submission when recaptcha is not configured" do
        allow(Settings::Authentication).to receive(:recaptcha_site_key).and_return(nil)
        allow(Settings::Authentication).to receive(:recaptcha_secret_key).and_return(nil)

        post "/lead_submissions", params: {
          organization_lead_form_id: lead_form.id,
          name: "Real User",
          email: "real@example.com",
          company: "Real Corp",
          job_title: "Dev"
        }, as: :json

        expect(response).to have_http_status(:ok)
        parsed = response.parsed_body
        expect(parsed["success"]).to be true
      end
    end
  end
end
