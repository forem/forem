require "rails_helper"

RSpec.describe "Admin::Subforems", type: :request do
  let(:admin_user) { create(:user, :admin) }

  before do
    sign_in admin_user
  end

  describe "GET /admin/subforems" do
    let!(:subforem1) { create(:subforem, domain: "#{rand(10_000)}.com") }
    let!(:subforem2) { create(:subforem, domain: "#{rand(10_000)}.com") }

    it "returns a successful response and lists subforems" do
      get admin_subforems_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Subforems")
      # Optionally verify that the subforems are ordered by created_at desc.
      expect(response.body).to match(/#{subforem2.domain}.*#{subforem1.domain}/m)
    end
  end

  describe "GET /admin/subforems/new" do
    it "renders the new subforem form" do
      get new_admin_subforem_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Subforem")
      # You may look for a form field or button text that confirms the correct template is rendered.
      expect(response.body).to include('form')
    end
  end

  describe "POST /admin/subforems" do
    context "with valid parameters" do
      let(:valid_params) { { subforem: { domain: "example.com", discoverable: true, root: false } } }

      it "creates a new subforem and redirects to the index" do
        expect {
          post admin_subforems_path, params: valid_params
        }.to change(Subforem, :count).by(1)

        # Follow the redirect to the index page.
        expect(response).to redirect_to(admin_subforems_path)
        follow_redirect!
        expect(response.body).to include(I18n.t("admin.subforems_controller.created"))
      end
    end

    context "with invalid parameters" do
      # Assuming there is a validation on presence of domain.
      let(:invalid_params) { { subforem: { domain: "", discoverable: true, root: false } } }

      it "does not create a subforem and re-renders the new form with errors" do
        expect {
          post admin_subforems_path, params: invalid_params
        }.not_to change(Subforem, :count)

        # When creation fails, the response should render the new template.
        expect(response.body).to include("error")
      end
    end
  end

  describe "GET /admin/subforems/:id/edit" do
    let!(:subforem) { create(:subforem) }

    it "renders the edit form" do
      get edit_admin_subforem_path(subforem)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit #{subforem.domain}")
      expect(response.body).to include('form')
    end
  end

  describe "PATCH /admin/subforems/:id" do
    let!(:subforem) { create(:subforem, domain: "old-domain.com", discoverable: false, root: false) }

    context "with valid parameters" do
      let(:update_params) { { subforem: { domain: "new-domain.com", discoverable: true, root: false } } }

      it "updates the subforem and redirects to the index" do
        patch admin_subforem_path(subforem), params: update_params
        expect(response).to redirect_to(admin_subforems_path)
        follow_redirect!
        expect(response.body).to include(I18n.t("admin.subforems_controller.updated"))
        subforem.reload
        expect(subforem.domain).to eq("new-domain.com")
      end
    end

    context "with invalid parameters" do
      let(:invalid_update_params) { { subforem: { domain: "" } } }

      it "does not update the subforem and re-renders the edit form with errors" do
        patch admin_subforem_path(subforem), params: invalid_update_params
        expect(response.body).to include("error")
        # The response should contain the form again for corrections.
        expect(response.body).to include("Edit Subforem")
      end
    end
  end
end
