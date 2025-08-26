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

  describe "GET /manage" do
    before do
      # Set the host to match the subforem domain so the middleware sets the correct subforem_id
      host! subforem.domain
    end

    context "when user is admin" do
      before { sign_in admin_user }

      it "returns a successful response" do
        get manage_subforem_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit")
        expect(response.body).to include("Supported Tags")
        expect(response.body).to include("Top Unsupported Tags")
      end
    end

    context "when user is subforem moderator for the current subforem" do
      before { sign_in moderator_user }

      it "returns a successful response" do
        get manage_subforem_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit")
      end
    end

    context "when user is not moderator for the current subforem" do
      let(:other_moderator) { create(:user) }
      let(:other_subforem) { create(:subforem, domain: "test2.com") }

      before do
        other_moderator.add_role(:subforem_moderator, other_subforem)
        sign_in other_moderator
      end

      it "returns forbidden" do
        get manage_subforem_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user is not signed in" do
      it "redirects to sign in" do
        get manage_subforem_path
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

  describe "POST /subforems/:id/add_tag" do
    let(:subforem) { create(:subforem) }
    let(:tag) { create(:tag) }

    context "when user is admin" do
      before { sign_in admin_user }

      it "adds a tag to supported tags" do
        expect do
          post add_tag_subforem_path(subforem), params: { tag_id: tag.id }
        end.to change { subforem.tag_relationships.where(supported: true).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include("success" => true)
      end

      it "updates existing unsupported relationship to supported" do
        # Create an unsupported relationship first
        relationship = subforem.tag_relationships.create!(tag: tag, supported: false)

        expect do
          post add_tag_subforem_path(subforem), params: { tag_id: tag.id }
        end.not_to change { subforem.tag_relationships.count }

        expect(relationship.reload.supported).to be true
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include("success" => true)
      end

      it "returns error for already supported tag" do
        subforem.tag_relationships.create!(tag: tag, supported: true)

        post add_tag_subforem_path(subforem), params: { tag_id: tag.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include("success" => false)
      end

      it "returns error for non-existent tag" do
        post add_tag_subforem_path(subforem), params: { tag_id: 99_999 }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include("success" => false)
      end
    end

    context "when user is subforem moderator" do
      before { sign_in moderator_user }

      it "adds a tag to supported tags" do
        expect do
          post add_tag_subforem_path(subforem), params: { tag_id: tag.id }
        end.to change { subforem.tag_relationships.where(supported: true).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include("success" => true)
      end
    end

    context "when user is super moderator" do
      before do
        moderator_user.add_role(:super_moderator)
        sign_in moderator_user
      end

      it "adds a tag to supported tags" do
        expect do
          post add_tag_subforem_path(subforem), params: { tag_id: tag.id }
        end.to change { subforem.tag_relationships.where(supported: true).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include("success" => true)
      end
    end

    context "when user is not authorized" do
      before { sign_in regular_user }

      it "returns forbidden" do
        post add_tag_subforem_path(subforem), params: { tag_id: tag.id }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        post add_tag_subforem_path(subforem), params: { tag_id: tag.id }

        expect(response).to redirect_to(new_magic_link_path)
      end
    end
  end

  describe "image upload functionality" do
    let(:subforem) { create(:subforem) }
    let(:image_file) { fixture_file_upload("800x600.png", "image/png") }

    before do
      # Stub FastImage to avoid HTTP requests in tests
      allow(FastImage).to receive(:size).and_return([100, 100])
    end

    context "when user is admin" do
      before { sign_in admin_user }

      it "uploads main logo image" do
        expect do
          put subforem_path(subforem), params: {
            subforem: { main_logo: image_file }
          }
        end.to change { Settings::General.logo_png(subforem_id: subforem.id) }

        expect(response).to redirect_to(subforems_path)
        expect(flash[:success]).to eq("Subforem updated successfully!")
      end

      it "uploads nav logo image" do
        expect do
          put subforem_path(subforem), params: {
            subforem: { nav_logo: image_file }
          }
        end.to change { Settings::General.resized_logo(subforem_id: subforem.id) }

        expect(response).to redirect_to(subforems_path)
        expect(flash[:success]).to eq("Subforem updated successfully!")
      end

      it "uploads social card image" do
        expect do
          put subforem_path(subforem), params: {
            subforem: { social_card: image_file }
          }
        end.to change { Settings::General.main_social_image(subforem_id: subforem.id) }

        expect(response).to redirect_to(subforems_path)
        expect(flash[:success]).to eq("Subforem updated successfully!")
      end
    end

    context "when user is super moderator" do
      before do
        moderator_user.add_role(:super_moderator)
        sign_in moderator_user
      end

      it "uploads main logo image" do
        expect do
          put subforem_path(subforem), params: {
            subforem: { main_logo: image_file }
          }
        end.to change { Settings::General.logo_png(subforem_id: subforem.id) }

        expect(response).to redirect_to(subforems_path)
        expect(flash[:success]).to eq("Subforem updated successfully!")
      end
    end

    context "when user is subforem moderator" do
      before { sign_in moderator_user }

      it "cannot upload images" do
        expect do
          put subforem_path(subforem), params: {
            subforem: { main_logo: image_file }
          }
        end.not_to change { Settings::General.logo_png(subforem_id: subforem.id) }

        expect(response).to redirect_to(subforems_path)
        expect(flash[:success]).to eq("Subforem updated successfully!")
      end
    end
  end
end
