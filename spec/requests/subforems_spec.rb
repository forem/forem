require "rails_helper"

RSpec.describe "Subforems", type: :request do
  let(:admin_user) { create(:user, :super_admin) }
  let(:moderator_user) { create(:user) }
  let(:regular_user) { create(:user) }
  let(:subforem) { create(:subforem, domain: "test1.com", discoverable: true) }

  before do
    moderator_user.add_role(:subforem_moderator, subforem)
  end

  describe "GET /subforems" do
    context "when user is admin" do
      before { sign_in admin_user }

      it "returns a successful response and lists all subforems" do
        get subforems_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Subforems")
      end
    end

    context "when user is subforem moderator" do
      before { sign_in moderator_user }

      it "returns a successful response and lists subforems" do
        get subforems_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Subforems")
        expect(response.body).to include(subforem.domain)
      end
    end

    context "when user is not admin or moderator" do
      before { sign_in regular_user }

      it "returns a successful response" do
        get subforems_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Subforems")
      end
    end

    context "when user is not signed in" do
      it "returns a successful response" do
        get subforems_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Subforems")
      end
    end
  end

  describe "GET /subforems/:id/edit" do
    context "when user is admin" do
      before { sign_in admin_user }

      it "returns a successful response" do
        get edit_subforem_path(subforem)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit #{subforem.domain}")
      end
    end

    context "when user is subforem moderator for the subforem" do
      before { sign_in moderator_user }

      it "returns a successful response" do
        get edit_subforem_path(subforem)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit #{subforem.domain}")
      end
    end

    context "when user is not moderator for the subforem" do
      let(:other_moderator) { create(:user) }
      let(:other_subforem) { create(:subforem, domain: "test2.com") }

      before do
        other_moderator.add_role(:subforem_moderator, other_subforem)
        sign_in other_moderator
      end

      it "returns forbidden" do
        get edit_subforem_path(subforem)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user is not signed in" do
      it "redirects to sign in" do
        get edit_subforem_path(subforem)
        expect(response).to redirect_to(new_magic_link_path)
      end
    end
  end

  describe "PATCH /subforems/:id" do
    context "when user is admin" do
      before { sign_in admin_user }

      it "updates the subforem and redirects to index" do
        patch subforem_path(subforem), params: { subforem: { discoverable: true } }
        expect(response).to redirect_to(subforems_path)
        expect(flash[:success]).to eq("Subforem updated successfully!")
      end

      it "can update all fields" do
        patch subforem_path(subforem), params: {
          subforem: { domain: "newdomain.com", discoverable: true },
          community_description: "New description",
          tagline: "New tagline"
        }
        expect(response).to redirect_to(subforems_path)
      end
    end

    context "when user is subforem moderator for the subforem" do
      before { sign_in moderator_user }

      it "updates the subforem and redirects to index" do
        patch subforem_path(subforem), params: { subforem: { discoverable: true } }
        expect(response).to redirect_to(subforems_path)
        expect(flash[:success]).to eq("Subforem updated successfully!")
      end

      it "can update community settings" do
        patch subforem_path(subforem), params: {
          subforem: { discoverable: true },
          community_description: "New description",
          tagline: "New tagline"
        }
        expect(response).to redirect_to(subforems_path)
      end

      it "cannot update restricted fields" do
        patch subforem_path(subforem), params: {
          subforem: { domain: "newdomain.com", discoverable: true }
        }
        expect(response).to redirect_to(subforems_path)
        # The domain should not be updated
        subforem.reload
        expect(subforem.domain).not_to eq("newdomain.com")
      end
    end

    context "when user is not moderator for the subforem" do
      let(:other_moderator) { create(:user) }
      let(:other_subforem) { create(:subforem, domain: "test3.com") }

      before do
        other_moderator.add_role(:subforem_moderator, other_subforem)
        sign_in other_moderator
      end

      it "returns forbidden" do
        patch subforem_path(subforem), params: { subforem: { discoverable: true } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user is not signed in" do
      it "redirects to sign in" do
        patch subforem_path(subforem), params: { subforem: { discoverable: true } }
        expect(response).to redirect_to(new_magic_link_path)
      end
    end

    context "when user is super moderator" do
      let(:super_moderator_user) { create(:user, :super_moderator) }

      before { sign_in super_moderator_user }

      it "can update logo and background image" do
        patch subforem_path(subforem), params: {
          subforem: { logo_url: "https://example.com/new-logo.png", bg_image_url: "https://example.com/new-bg.jpg" }
        }
        expect(response).to redirect_to(subforems_path)
        expect(flash[:success]).to eq("Subforem updated successfully!")
      end

      it "can update community settings" do
        patch subforem_path(subforem), params: {
          subforem: { logo_url: "https://example.com/logo.png" },
          community_description: "New description",
          tagline: "New tagline",
          internal_content_description_spec: "New content spec"
        }
        expect(response).to redirect_to(subforems_path)
      end

      it "cannot update domain, name, or discoverable" do
        original_domain = subforem.domain
        original_discoverable = subforem.discoverable

        patch subforem_path(subforem), params: {
          subforem: { domain: "newdomain.com", discoverable: false }
        }
        expect(response).to redirect_to(subforems_path)

        # The restricted fields should not be updated
        subforem.reload
        expect(subforem.domain).to eq(original_domain)
        expect(subforem.discoverable).to eq(original_discoverable)
      end
    end
  end
end
