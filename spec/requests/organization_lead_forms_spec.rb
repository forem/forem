require "rails_helper"

RSpec.describe "OrganizationLeadForms" do
  let(:user) { create(:user, :org_admin) }
  let(:organization) { user.organizations.first }

  describe "GET /:slug/settings/lead_forms" do
    context "when signed in as org admin" do
      before { sign_in user }

      it "renders the lead forms page" do
        get "/#{organization.slug}/settings/lead_forms"
        expect(response).to have_http_status(:ok)
      end

      it "shows existing lead forms" do
        form = create(:organization_lead_form, organization: organization, title: "Newsletter Signup")
        get "/#{organization.slug}/settings/lead_forms"
        expect(response.body).to include("Newsletter Signup")
      end
    end

    context "when not an admin" do
      let(:member) { create(:user) }

      before do
        create(:organization_membership, organization: organization, user: member, type_of_user: "member")
        sign_in member
      end

      it "denies access" do
        expect do
          get "/#{organization.slug}/settings/lead_forms"
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /:slug/settings/lead_forms" do
    before { sign_in user }

    it "creates a new lead form" do
      expect do
        post "/#{organization.slug}/settings/lead_forms", params: {
          organization_lead_form: { title: "Demo Request", description: "Book a demo", button_text: "Request Demo" },
        }
      end.to change(OrganizationLeadForm, :count).by(1)

      expect(response).to redirect_to(organization_lead_forms_path(organization.slug))
      form = OrganizationLeadForm.last
      expect(form.title).to eq("Demo Request")
      expect(form.button_text).to eq("Request Demo")
    end

    it "rejects invalid forms" do
      post "/#{organization.slug}/settings/lead_forms", params: {
        organization_lead_form: { title: "", button_text: "" },
      }
      expect(response).to have_http_status(:ok) # re-renders index
      expect(OrganizationLeadForm.count).to eq(0)
    end
  end

  describe "DELETE /:slug/settings/lead_forms/:id" do
    before { sign_in user }

    it "deletes a lead form" do
      form = create(:organization_lead_form, organization: organization)
      expect do
        delete "/#{organization.slug}/settings/lead_forms/#{form.id}"
      end.to change(OrganizationLeadForm, :count).by(-1)

      expect(response).to redirect_to(organization_lead_forms_path(organization.slug))
    end
  end

  describe "PATCH /:slug/settings/lead_forms/:id/toggle" do
    before { sign_in user }

    it "toggles active status" do
      form = create(:organization_lead_form, organization: organization, active: true)
      patch "/#{organization.slug}/settings/lead_forms/#{form.id}/toggle"

      expect(form.reload.active).to be false
      expect(response).to redirect_to(organization_lead_forms_path(organization.slug))
    end
  end

  describe "GET /:slug/settings/lead_forms/:id/submissions" do
    before { sign_in user }

    it "downloads CSV of submissions" do
      form = create(:organization_lead_form, organization: organization)
      submission_user = create(:user, name: "Lead Person", email: "lead@example.com")
      create(:lead_submission, organization_lead_form: form, user: submission_user,
                               name: "Lead Person", email: "lead@example.com")

      get "/#{organization.slug}/settings/lead_forms/#{form.id}/submissions", params: { format: :csv }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("text/csv")
      expect(response.body).to include("Lead Person")
      expect(response.body).to include("lead@example.com")
    end
  end
end
