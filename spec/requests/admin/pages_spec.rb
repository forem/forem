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
end
