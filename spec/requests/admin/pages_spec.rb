require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/customization/pages" do
  it_behaves_like "an InternalPolicy dependant request", Page do
    let(:request) { get admin_pages_path }
  end

  describe "when managing feature flags" do
    it "allows tech admins to manage the feature flag for a page" do
      user = create(:user, :admin, :tech_admin)
      sign_in user
      get new_admin_page_path
      expect(response.body).to include("Feature Flag")
    end

    it "does not allow non tech admins to manage the feature flag for a page" do
      sign_in create(:user, :admin)
      get new_admin_page_path
      expect(response.body).not_to include("Feature Flag")
    end

    it "prefills the page when page param is passed to new" do
      page = create(:page)
      sign_in create(:user, :admin)
      get new_admin_page_path, params: { page: page.id }
      expect(response.body).to include(" (Forking <code style='margin-left: 8px;'>#{page.slug}</code>)")
    end
  end

  describe "mass assignment security" do
    let(:admin) { create(:user, :super_admin) }
    let(:organization) { create(:organization) }

    before { sign_in admin }

    it "filters out organization_id on create" do
      expect {
        post admin_pages_path, params: {
          page: {
            title: "Test Spoof",
            description: "A page",
            slug: "test-spoof",
            template: "contained",
            body_markdown: "hello",
            organization_id: organization.id
          }
        }
      }.to change(Page, :count).by(1)

      expect(Page.last.organization_id).to be_nil
    end

    it "filters out organization_id on update" do
      page_record = create(:page)
      patch admin_page_path(page_record), params: {
        page: { organization_id: organization.id }
      }
      expect(page_record.reload.organization_id).to be_nil
    end
  end
end
