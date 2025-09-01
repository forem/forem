require "rails_helper"

RSpec.describe "Admin::Subforems", type: :request do
  let(:admin_user) { create(:user, :super_admin) }

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
      expect(response.body).to include("form")
    end

    it "includes all the new form fields" do
      get new_admin_subforem_path
      expect(response.body).to include('name="subforem[domain]"')
      expect(response.body).to include('name="subforem[name]"')
      expect(response.body).to include('name="subforem[brain_dump]"')
      expect(response.body).to include('name="subforem[logo_url]"')
      expect(response.body).to include('name="subforem[bg_image_url]"')
      expect(response.body).to include('name="subforem[discoverable]"')
    end
  end

  describe "POST /admin/subforems" do
    context "with create_from_scratch parameters" do
      let(:valid_scratch_params) do
        {
          subforem: {
            domain: "example.com",
            name: "Test Community",
            brain_dump: "A community for testing purposes",
            logo_url: "https://example.com/logo.png",
            bg_image_url: "https://example.com/background.jpg",
            discoverable: true,
            root: false
          }
        }
      end

      before do
        allow(Subforems::CreateFromScratchWorker).to receive(:perform_async)
      end

      it "creates a new subforem using create_from_scratch! and queues background job" do
        expect do
          post admin_subforems_path, params: valid_scratch_params
        end.to change(Subforem, :count).by(1)

        expect(Subforems::CreateFromScratchWorker).to have_received(:perform_async).with(
          Subforem.last.id,
          "A community for testing purposes",
          "Test Community",
          "https://example.com/logo.png",
          "https://example.com/background.jpg",
          "en",
        )

        # Follow the redirect to the index page.
        expect(response).to redirect_to(admin_subforems_path)
        follow_redirect!
        expect(response.body).to include(I18n.t("admin.subforems_controller.created_with_ai"))
      end

      it "works without background image URL" do
        params_without_bg = valid_scratch_params.deep_dup
        params_without_bg[:subforem].delete(:bg_image_url)

        expect do
          post admin_subforems_path, params: params_without_bg
        end.to change(Subforem, :count).by(1)

        expect(Subforems::CreateFromScratchWorker).to have_received(:perform_async).with(
          Subforem.last.id,
          "A community for testing purposes",
          "Test Community",
          "https://example.com/logo.png",
          nil,
          "en",
        )
      end
    end

    context "with regular parameters (fallback)" do
      let(:valid_params) { { subforem: { domain: "example.com", discoverable: true, root: false } } }

      it "creates a new subforem using regular save and redirects to the index" do
        expect do
          post admin_subforems_path, params: valid_params
        end.to change(Subforem, :count).by(1)

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
        expect do
          post admin_subforems_path, params: invalid_params
        end.not_to change(Subforem, :count)

        # When creation fails, the response should render the new template.
        expect(response.body).to include("error")
      end
    end

    context "with partial create_from_scratch parameters" do
      let(:partial_params) do
        {
          subforem: {
            domain: "example.com",
            name: "Test Community",
            # Missing brain_dump and logo_url
            discoverable: true,
            root: false
          }
        }
      end

      it "falls back to regular creation" do
        expect do
          post admin_subforems_path, params: partial_params
        end.to change(Subforem, :count).by(1)

        expect(response).to redirect_to(admin_subforems_path)
        follow_redirect!
        expect(response.body).to include(I18n.t("admin.subforems_controller.created"))
      end
    end
  end

  describe "GET /admin/subforems/:id/edit" do
    let!(:subforem) { create(:subforem) }

    it "renders the edit form" do
      get edit_admin_subforem_path(subforem)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit #{subforem.domain}")
      expect(response.body).to include("form")
    end
  end

  describe "PATCH /admin/subforems/:id" do
    let!(:subforem) { create(:subforem) }
    let(:update_params) { { subforem: { domain: "updated.com", discoverable: false } } }

    it "updates the subforem and redirects to the index" do
      patch admin_subforem_path(subforem), params: update_params
      expect(response).to redirect_to(admin_subforems_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("admin.subforems_controller.updated"))
    end
  end
end
