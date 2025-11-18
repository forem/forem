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

      it "updates the subforem and redirects to manage page" do
        patch subforem_path(subforem), params: { subforem: { discoverable: true } }
        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.messages.updated"))
      end

      it "can update all fields including community settings" do
        # Allow the actual Settings methods to be called instead of using stubs
        allow(Settings::Community).to receive(:community_description).and_call_original
        allow(Settings::Community).to receive(:community_name).and_call_original
        allow(Settings::Community).to receive(:tagline).and_call_original
        allow(Settings::Community).to receive(:member_label).and_call_original
        
        patch subforem_path(subforem), params: {
          subforem: { domain: "newdomain.com", discoverable: true },
          community_name: "New Community Name",
          community_description: "New description",
          tagline: "New tagline",
          member_label: "developer"
        }
        expect(response).to redirect_to(manage_subforem_path)
        
        expect(Settings::Community.community_name(subforem_id: subforem.id)).to eq("New Community Name")
        expect(Settings::Community.community_description(subforem_id: subforem.id)).to eq("New description")
        expect(Settings::Community.tagline(subforem_id: subforem.id)).to eq("New tagline")
        expect(Settings::Community.member_label(subforem_id: subforem.id)).to eq("developer")
      end

      it "can update user experience settings" do
        patch subforem_path(subforem), params: {
          subforem: { discoverable: true },
          feed_style: "rich",
          feed_lookback_days: "30",
          primary_brand_color_hex: "#1a1a1a"
        }
        expect(response).to redirect_to(manage_subforem_path)
        
        # Reload subforem to clear any cached settings
        subforem.reload
        
        expect(Settings::UserExperience.feed_style(subforem_id: subforem.id)).to eq("rich")
        expect(Settings::UserExperience.feed_lookback_days(subforem_id: subforem.id)).to eq(30)
        expect(Settings::UserExperience.primary_brand_color_hex(subforem_id: subforem.id)).to eq("#1a1a1a")
      end
    end

    context "when user is subforem moderator for the subforem" do
      before { sign_in moderator_user }

      it "updates the subforem and redirects to manage page" do
        patch subforem_path(subforem), params: { subforem: { discoverable: true } }
        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.messages.updated"))
      end

      it "can update community settings" do
        # Allow the actual Settings methods to be called instead of using stubs
        allow(Settings::Community).to receive(:community_description).and_call_original
        allow(Settings::Community).to receive(:tagline).and_call_original
        allow(Settings::Community).to receive(:member_label).and_call_original
        
        patch subforem_path(subforem), params: {
          subforem: { discoverable: true },
          community_description: "New description",
          tagline: "New tagline",
          member_label: "user"
        }
        expect(response).to redirect_to(manage_subforem_path)
        
        expect(Settings::Community.community_description(subforem_id: subforem.id)).to eq("New description")
        expect(Settings::Community.tagline(subforem_id: subforem.id)).to eq("New tagline")
        expect(Settings::Community.member_label(subforem_id: subforem.id)).to eq("user")
      end

      it "can update user experience settings" do
        patch subforem_path(subforem), params: {
          subforem: { discoverable: true },
          feed_style: "compact",
          feed_lookback_days: "15"
        }
        expect(response).to redirect_to(manage_subforem_path)
        expect(Settings::UserExperience.feed_style(subforem_id: subforem.id)).to eq("compact")
        expect(Settings::UserExperience.feed_lookback_days(subforem_id: subforem.id)).to eq(15)
      end

      it "cannot update restricted fields like domain" do
        original_domain = subforem.domain
        patch subforem_path(subforem), params: {
          subforem: { domain: "newdomain.com", discoverable: true }
        }
        expect(response).to redirect_to(manage_subforem_path)
        # The domain should not be updated
        subforem.reload
        expect(subforem.domain).to eq(original_domain)
        expect(subforem.domain).not_to eq("newdomain.com")
      end

      it "cannot update community_name even if parameter is provided" do
        original_name = Settings::Community.community_name(subforem_id: subforem.id)
        
        patch subforem_path(subforem), params: {
          subforem: { discoverable: true },
          community_name: "Hacked Community Name"
        }
        expect(response).to redirect_to(manage_subforem_path)
        
        # Community name should NOT be updated
        expect(Settings::Community.community_name(subforem_id: subforem.id)).to eq(original_name)
        expect(Settings::Community.community_name(subforem_id: subforem.id)).not_to eq("Hacked Community Name")
      end

      it "can update primary_brand_color_hex" do
        patch subforem_path(subforem), params: {
          subforem: { discoverable: true },
          primary_brand_color_hex: "#1a1a1a"
        }
        expect(response).to redirect_to(manage_subforem_path)
        expect(Settings::UserExperience.primary_brand_color_hex(subforem_id: subforem.id)).to eq("#1a1a1a")
      end

      it "can update internal_content_description_spec" do
        patch subforem_path(subforem), params: {
          subforem: { discoverable: true },
          internal_content_description_spec: "New spec for moderators"
        }
        expect(response).to redirect_to(manage_subforem_path)
        expect(Settings::RateLimit.internal_content_description_spec(subforem_id: subforem.id)).to eq("New spec for moderators")
      end

      it "cannot update discoverable field (admin-only)" do
        subforem.update!(discoverable: false)
        
        patch subforem_path(subforem), params: {
          subforem: { discoverable: true }
        }
        expect(response).to redirect_to(manage_subforem_path)
        
        subforem.reload
        # Moderators can no longer update discoverable
        expect(subforem.discoverable).to be false
      end

      it "can update sidebar_tags" do
        patch subforem_path(subforem), params: {
          sidebar_tags: "ruby,rails,javascript"
        }
        expect(response).to redirect_to(manage_subforem_path)
        expect(Settings::General.sidebar_tags(subforem_id: subforem.id)).to eq(%w[ruby rails javascript])
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

      it "can update settings and redirects to manage page" do
        patch subforem_path(subforem), params: {
          subforem: { logo_url: "https://example.com/new-logo.png", bg_image_url: "https://example.com/new-bg.jpg" }
        }
        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.messages.updated"))
      end

      it "can update community settings and user experience settings" do
        # Allow the actual Settings methods to be called instead of using stubs
        allow(Settings::Community).to receive(:community_description).and_call_original
        allow(Settings::Community).to receive(:tagline).and_call_original
        allow(Settings::Community).to receive(:member_label).and_call_original
        allow(Settings::RateLimit).to receive(:internal_content_description_spec).and_call_original
        allow(Settings::UserExperience).to receive(:feed_style).and_call_original
        allow(Settings::UserExperience).to receive(:primary_brand_color_hex).and_call_original
        
        patch subforem_path(subforem), params: {
          subforem: { logo_url: "https://example.com/logo.png" },
          community_description: "New description",
          tagline: "New tagline",
          member_label: "contributor",
          internal_content_description_spec: "New content spec",
          feed_style: "basic",
          primary_brand_color_hex: "#0a0a0a"
        }
        expect(response).to redirect_to(manage_subforem_path)
        
        expect(Settings::Community.community_description(subforem_id: subforem.id)).to eq("New description")
        expect(Settings::Community.tagline(subforem_id: subforem.id)).to eq("New tagline")
        expect(Settings::Community.member_label(subforem_id: subforem.id)).to eq("contributor")
        expect(Settings::RateLimit.internal_content_description_spec(subforem_id: subforem.id)).to eq("New content spec")
        expect(Settings::UserExperience.feed_style(subforem_id: subforem.id)).to eq("basic")
        expect(Settings::UserExperience.primary_brand_color_hex(subforem_id: subforem.id)).to eq("#0a0a0a")
      end

      it "cannot update domain, name, or discoverable" do
        original_domain = subforem.domain
        original_discoverable = subforem.discoverable

        patch subforem_path(subforem), params: {
          subforem: { domain: "newdomain.com", discoverable: false }
        }
        expect(response).to redirect_to(manage_subforem_path)

        # The restricted fields should not be updated
        subforem.reload
        expect(subforem.domain).to eq(original_domain)
        expect(subforem.discoverable).to eq(original_discoverable)
      end

      it "cannot update community_name even if parameter is provided" do
        original_name = Settings::Community.community_name(subforem_id: subforem.id)
        
        patch subforem_path(subforem), params: {
          subforem: { logo_url: "https://example.com/logo.png" },
          community_name: "Super Moderator Hack Attempt"
        }
        expect(response).to redirect_to(manage_subforem_path)
        
        # Community name should NOT be updated (only admins can update this)
        expect(Settings::Community.community_name(subforem_id: subforem.id)).to eq(original_name)
        expect(Settings::Community.community_name(subforem_id: subforem.id)).not_to eq("Super Moderator Hack Attempt")
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

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.messages.updated"))
      end

      it "uploads nav logo image" do
        expect do
          put subforem_path(subforem), params: {
            subforem: { nav_logo: image_file }
          }
        end.to change { Settings::General.resized_logo(subforem_id: subforem.id) }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.messages.updated"))
      end

      it "uploads social card image" do
        expect do
          put subforem_path(subforem), params: {
            subforem: { social_card: image_file }
          }
        end.to change { Settings::General.main_social_image(subforem_id: subforem.id) }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.messages.updated"))
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

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.messages.updated"))
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

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.messages.updated"))
      end
    end
  end

  describe "DELETE /subforems/:id/remove_tag" do
    let(:subforem) { create(:subforem) }
    let(:tag) { create(:tag) }

    context "when user is admin" do
      before do
        sign_in admin_user
        subforem.tag_relationships.create!(tag: tag, supported: true)
      end

      it "removes a tag from supported tags" do
        expect do
          delete remove_tag_subforem_path(subforem), params: { tag_id: tag.id }
        end.to change { subforem.tag_relationships.where(supported: true).count }.by(-1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include("success" => true)
      end

      it "returns error for tag that is not supported" do
        unsupported_tag = create(:tag)

        delete remove_tag_subforem_path(subforem), params: { tag_id: unsupported_tag.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include("success" => false)
      end
    end

    context "when user is subforem moderator" do
      before do
        sign_in moderator_user
        subforem.tag_relationships.create!(tag: tag, supported: true)
      end

      it "removes a tag from supported tags" do
        expect do
          delete remove_tag_subforem_path(subforem), params: { tag_id: tag.id }
        end.to change { subforem.tag_relationships.where(supported: true).count }.by(-1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include("success" => true)
      end
    end

    context "when user is not authorized" do
      before { sign_in regular_user }

      it "returns forbidden" do
        delete remove_tag_subforem_path(subforem), params: { tag_id: tag.id }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /subforems/:id/create_navigation_link" do
    let(:subforem) { create(:subforem) }
    let(:valid_params) do
      {
        navigation_link: {
          name: "Test Link",
          url: "/test",
          icon: "<svg xmlns='http://www.w3.org/2000/svg'></svg>",
          section: "default",
          display_to: "all",
          position: 1
        }
      }
    end

    context "when user is admin" do
      before { sign_in admin_user }

      it "creates a navigation link" do
        expect do
          post create_navigation_link_subforem_path(subforem), params: valid_params
        end.to change { NavigationLink.count }.by(1)

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.navigation_links.messages.created"))
        
        link = NavigationLink.last
        expect(link.subforem_id).to eq(subforem.id)
        expect(link.name).to eq("Test Link")
      end

      it "handles validation errors" do
        invalid_params = { navigation_link: { name: "", url: "", icon: "" } }
        
        expect do
          post create_navigation_link_subforem_path(subforem), params: invalid_params
        end.not_to change { NavigationLink.count }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:error]).to be_present
      end
    end

    context "when user is subforem moderator" do
      before { sign_in moderator_user }

      it "creates a navigation link" do
        expect do
          post create_navigation_link_subforem_path(subforem), params: valid_params
        end.to change { NavigationLink.count }.by(1)

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.navigation_links.messages.created"))
      end
    end

    context "when user is not authorized" do
      before { sign_in regular_user }

      it "returns forbidden" do
        post create_navigation_link_subforem_path(subforem), params: valid_params

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with image upload" do
      before do
        sign_in admin_user
        # Allow MiniMagick operations to be skipped in tests
        allow_any_instance_of(NavigationLinkImageUploader).to receive(:validate_frame_count)
        allow_any_instance_of(NavigationLinkImageUploader).to receive(:strip_exif)
      end

      it "creates a navigation link with an image instead of SVG" do
        image_file = fixture_file_upload("800x600.png", "image/png")
        params = {
          navigation_link: {
            name: "Image Link",
            url: "/image-test",
            image: image_file,
            section: "default",
            display_to: "all",
            position: 1
          }
        }

        expect do
          post create_navigation_link_subforem_path(subforem), params: params
        end.to change { NavigationLink.count }.by(1)

        link = NavigationLink.last
        expect(link.subforem_id).to eq(subforem.id)
        expect(link.name).to eq("Image Link")
        expect(link.read_attribute(:image)).to be_present
        expect(link.image.url).to be_present
      end

      it "creates navigation link with default icon when neither icon nor image is provided" do
        params = {
          navigation_link: {
            name: "No Icon Link",
            url: "/no-icon",
            section: "default",
            display_to: "all",
            position: 1
          }
        }

        expect do
          post create_navigation_link_subforem_path(subforem), params: params
        end.to change { NavigationLink.count }.by(1)

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to be_present
        
        link = NavigationLink.last
        expect(link.icon).to eq(NavigationLink.default_icon_svg)
      end
    end

    context "cache busting" do
      before { sign_in admin_user }

      it "busts navigation links cache on create" do
        allow(EdgeCache::Bust).to receive(:call)
        
        post create_navigation_link_subforem_path(subforem), params: valid_params
        
        expect(EdgeCache::Bust).to have_received(:call).with("/async_info/navigation_links")
        expect(EdgeCache::Bust).to have_received(:call).with(["/onboarding/tags", "/onboarding", "/"])
      end
    end
  end

  describe "PATCH /subforems/:id/update_navigation_link" do
    let(:subforem) { create(:subforem) }
    let!(:navigation_link) do
      NavigationLink.create!(
        subforem: subforem,
        name: "Original Link",
        url: "/original",
        icon: "<svg xmlns='http://www.w3.org/2000/svg'></svg>",
        section: "default",
        display_to: "all",
        position: 1
      )
    end

    context "route structure" do
      it "uses path parameter for navigation_link_id" do
        # Verify the route includes navigation_link_id as a path parameter, not query parameter
        expected_path = "/subforems/#{subforem.id}/update_navigation_link/#{navigation_link.id}"
        generated_path = update_navigation_link_subforem_path(subforem, navigation_link.id)
        
        expect(generated_path).to eq(expected_path)
      end

      it "accepts positional argument for navigation_link_id" do
        # This confirms the fix for the 404 issue - path parameter instead of query parameter
        path = update_navigation_link_subforem_path(subforem, navigation_link.id)
        expect(path).to include("/update_navigation_link/#{navigation_link.id}")
        expect(path).not_to include("navigation_link_id=")
      end
    end

    context "when user is admin" do
      before { sign_in admin_user }

      it "updates a navigation link" do
        patch update_navigation_link_subforem_path(subforem, navigation_link.id),
              params: { navigation_link: { name: "Updated Link", url: "/updated" } }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.navigation_links.messages.updated"))
        
        navigation_link.reload
        expect(navigation_link.name).to eq("Updated Link")
        expect(navigation_link.url).to eq("/updated")
      end

      it "prevents updating navigation link from different subforem" do
        other_subforem = create(:subforem)
        other_link = NavigationLink.create!(
          subforem: other_subforem,
          name: "Other Link",
          url: "/other",
          icon: "<svg xmlns='http://www.w3.org/2000/svg'></svg>",
          section: "default",
          display_to: "all",
          position: 1
        )

        patch update_navigation_link_subforem_path(subforem, other_link.id),
              params: { navigation_link: { name: "Hacked" } }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:error]).to eq(I18n.t("views.subforems.edit.navigation_links.messages.not_found"))
        
        other_link.reload
        expect(other_link.name).to eq("Other Link")
      end
    end

    context "when user is subforem moderator" do
      before { sign_in moderator_user }

      it "updates a navigation link" do
        patch update_navigation_link_subforem_path(subforem, navigation_link.id),
              params: { navigation_link: { name: "Updated by Mod" } }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.navigation_links.messages.updated"))
        
        navigation_link.reload
        expect(navigation_link.name).to eq("Updated by Mod")
      end
    end

    context "when user is not authorized" do
      before { sign_in regular_user }

      it "returns forbidden" do
        patch update_navigation_link_subforem_path(subforem, navigation_link.id),
              params: { navigation_link: { name: "Hacked" } }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "cache busting" do
      before { sign_in admin_user }

      it "busts navigation links cache on update" do
        allow(EdgeCache::Bust).to receive(:call)
        
        patch update_navigation_link_subforem_path(subforem, navigation_link.id),
              params: { navigation_link: { name: "Updated Link" } }
        
        expect(EdgeCache::Bust).to have_received(:call).with("/async_info/navigation_links")
        expect(EdgeCache::Bust).to have_received(:call).with(["/onboarding/tags", "/onboarding", "/"])
      end
    end

    context "with image upload" do
      before do
        sign_in admin_user
        # Allow MiniMagick operations to be skipped in tests
        allow_any_instance_of(NavigationLinkImageUploader).to receive(:validate_frame_count)
        allow_any_instance_of(NavigationLinkImageUploader).to receive(:strip_exif)
      end

      it "updates a navigation link with an image" do
        image_file = fixture_file_upload("800x600.png", "image/png")
        
        patch update_navigation_link_subforem_path(subforem, navigation_link.id),
              params: { navigation_link: { image: image_file } }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.navigation_links.messages.updated"))
        
        navigation_link.reload
        expect(navigation_link.read_attribute(:image)).to be_present
        expect(navigation_link.image.url).to be_present
      end
    end
  end

  describe "DELETE /subforems/:id/destroy_navigation_link" do
    let(:subforem) { create(:subforem) }
    let!(:navigation_link) do
      NavigationLink.create!(
        subforem: subforem,
        name: "Link to Delete",
        url: "/delete",
        icon: "<svg xmlns='http://www.w3.org/2000/svg'></svg>",
        section: "default",
        display_to: "all",
        position: 1
      )
    end

    context "when user is admin" do
      before { sign_in admin_user }

      it "deletes a navigation link" do
        expect do
          delete destroy_navigation_link_subforem_path(subforem, navigation_link_id: navigation_link.id)
        end.to change { NavigationLink.count }.by(-1)

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.navigation_links.messages.deleted"))
      end

      it "prevents deleting navigation link from different subforem" do
        other_subforem = create(:subforem)
        other_link = NavigationLink.create!(
          subforem: other_subforem,
          name: "Other Link",
          url: "/other",
          icon: "<svg xmlns='http://www.w3.org/2000/svg'></svg>",
          section: "default",
          display_to: "all",
          position: 1
        )

        expect do
          delete destroy_navigation_link_subforem_path(subforem, navigation_link_id: other_link.id)
        end.not_to change { NavigationLink.count }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:error]).to eq(I18n.t("views.subforems.edit.navigation_links.messages.not_found"))
      end
    end

    context "when user is subforem moderator" do
      before { sign_in moderator_user }

      it "deletes a navigation link" do
        expect do
          delete destroy_navigation_link_subforem_path(subforem, navigation_link_id: navigation_link.id)
        end.to change { NavigationLink.count }.by(-1)

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.edit.navigation_links.messages.deleted"))
      end
    end

    context "when user is not authorized" do
      before { sign_in regular_user }

      it "returns forbidden" do
        delete destroy_navigation_link_subforem_path(subforem, navigation_link_id: navigation_link.id)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "cache busting" do
      before { sign_in admin_user }

      it "busts navigation links cache on delete" do
        allow(EdgeCache::Bust).to receive(:call)
        
        delete destroy_navigation_link_subforem_path(subforem, navigation_link_id: navigation_link.id)
        
        expect(EdgeCache::Bust).to have_received(:call).with("/async_info/navigation_links")
        expect(EdgeCache::Bust).to have_received(:call).with(["/onboarding/tags", "/onboarding", "/"])
      end
    end
  end

  describe "GET /subforems/:id/new_page" do
    let(:subforem) { create(:subforem) }

    context "when user is admin" do
      before { sign_in admin_user }

      it "returns a successful response" do
        get new_page_subforem_path(subforem)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Create New Page")
      end
    end

    context "when user is subforem moderator" do
      before { sign_in moderator_user }

      it "returns a successful response" do
        get new_page_subforem_path(subforem)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Create New Page")
      end
    end

    context "when user is not authorized" do
      before { sign_in regular_user }

      it "returns forbidden" do
        get new_page_subforem_path(subforem)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user is not signed in" do
      it "redirects to sign in" do
        get new_page_subforem_path(subforem)
        expect(response).to redirect_to(new_magic_link_path)
      end
    end
  end

  describe "POST /subforems/:id/create_page" do
    let(:subforem) { create(:subforem) }
    let(:valid_page_params) do
      {
        page: {
          title: "Test Page",
          slug: "test-page",
          description: "A test page",
          body_markdown: "# Welcome\n\nThis is test content."
        }
      }
    end

    context "when user is admin" do
      before { sign_in admin_user }

      it "creates a page" do
        expect do
          post create_page_subforem_path(subforem), params: valid_page_params
        end.to change { Page.count }.by(1)

        page = Page.last
        expect(response).to redirect_to("/page/#{page.slug}")
        expect(flash[:success]).to eq(I18n.t("views.subforems.pages.created"))

        expect(page.subforem_id).to eq(subforem.id)
        expect(page.title).to eq("Test Page")
        expect(page.slug).to eq("test-page")
        expect(page.template).to eq("contained")
        expect(page.is_top_level_path).to be false
        expect(page.body_markdown).to be_present
        expect(page.body_html).to be_nil
        expect(page.body_json).to be_nil
        expect(page.body_css).to be_nil
      end

      it "forces markdown-only content" do
        post create_page_subforem_path(subforem), params: {
          page: {
            title: "HTML Test",
            slug: "html-test",
            description: "Test",
            body_markdown: "# Test",
            body_html: "<div>Should be ignored</div>",
            body_json: { test: "Should be ignored" }.to_json
          }
        }

        page = Page.last
        expect(page.body_markdown).to eq("# Test")
        expect(page.body_html).to be_nil
        expect(page.body_json).to be_nil
      end

      it "forces contained template and non-top-level path" do
        post create_page_subforem_path(subforem), params: {
          page: {
            title: "Template Test",
            slug: "template-test",
            description: "Test",
            body_markdown: "# Test",
            template: "full_within_layout",
            is_top_level_path: true
          }
        }

        page = Page.last
        expect(page.template).to eq("contained")
        expect(page.is_top_level_path).to be false
      end

      it "handles validation errors" do
        invalid_params = { page: { title: "", slug: "", description: "" } }

        expect do
          post create_page_subforem_path(subforem), params: invalid_params
        end.not_to change { Page.count }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Create New Page")
      end
    end

    context "when user is subforem moderator" do
      before { sign_in moderator_user }

      it "creates a page" do
        expect do
          post create_page_subforem_path(subforem), params: valid_page_params
        end.to change { Page.count }.by(1)

        page = Page.last
        expect(response).to redirect_to("/page/#{page.slug}")
        expect(flash[:success]).to eq(I18n.t("views.subforems.pages.created"))

        expect(page.subforem_id).to eq(subforem.id)
      end
    end

    context "when user is not authorized" do
      before { sign_in regular_user }

      it "returns forbidden" do
        post create_page_subforem_path(subforem), params: valid_page_params
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /subforems/:id/edit_page/:page_id" do
    let(:subforem) { create(:subforem) }
    let!(:subforem_page) do
      create(:page, subforem: subforem, title: "Subforem Page", slug: "subforem-page",
                    description: "Test", body_markdown: "# Test", is_top_level_path: false)
    end
    let!(:top_level_page) do
      create(:page, subforem: subforem, title: "Top Level", slug: "top-level",
                    description: "Test", body_markdown: "# Test", is_top_level_path: true)
    end

    context "when user is admin" do
      before { sign_in admin_user }

      it "returns a successful response for subforem page" do
        get edit_page_subforem_path(subforem, page_id: subforem_page.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit #{subforem_page.title}")
      end

      it "returns a successful response for top-level page that belongs to subforem" do
        get edit_page_subforem_path(subforem, page_id: top_level_page.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit #{top_level_page.title}")
      end
    end

    context "when user is subforem moderator" do
      before { sign_in moderator_user }

      it "returns a successful response for regular page" do
        get edit_page_subforem_path(subforem, page_id: subforem_page.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit #{subforem_page.title}")
      end

      it "can edit top-level pages that belong to their subforem" do
        get edit_page_subforem_path(subforem, page_id: top_level_page.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit #{top_level_page.title}")
      end
    end

    context "when page belongs to different subforem" do
      let(:other_subforem) { create(:subforem, domain: "other.com") }
      let!(:other_regular_page) do
        create(:page, subforem: other_subforem, title: "Other Page", slug: "other-page",
                      description: "Test", body_markdown: "# Test", is_top_level_path: false)
      end
      let!(:other_top_level_page) do
        create(:page, subforem: other_subforem, title: "Other Top Level", slug: "other-top",
                      description: "Test", body_markdown: "# Test", is_top_level_path: true)
      end

      before { sign_in moderator_user }

      it "blocks editing regular pages from other subforems" do
        get edit_page_subforem_path(subforem, page_id: other_regular_page.id)
        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:error]).to eq(I18n.t("views.subforems.pages.not_found"))
      end

      it "blocks editing top-level pages from other subforems" do
        get edit_page_subforem_path(subforem, page_id: other_top_level_page.id)
        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:error]).to eq(I18n.t("views.subforems.pages.not_found"))
      end
    end

    context "when user is not authorized" do
      before { sign_in regular_user }

      it "returns forbidden" do
        get edit_page_subforem_path(subforem, page_id: subforem_page.id)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /subforems/:id/update_page/:page_id" do
    let(:subforem) { create(:subforem) }
    let!(:subforem_page) do
      create(:page, subforem: subforem, title: "Original Title", slug: "original-slug",
                    description: "Original description", body_markdown: "# Original", is_top_level_path: false)
    end
    let!(:top_level_page) do
      create(:page, subforem: subforem, title: "Top Level", slug: "top-level",
                    description: "Top level page", body_markdown: "# Top Level", is_top_level_path: true)
    end

    context "when user is admin" do
      before { sign_in admin_user }

      it "updates a subforem page" do
        patch update_page_subforem_path(subforem, page_id: subforem_page.id), params: {
          page: {
            title: "Updated Title",
            slug: "updated-slug",
            description: "Updated description",
            body_markdown: "# Updated Content"
          }
        }

        subforem_page.reload
        expect(response).to redirect_to("/page/#{subforem_page.slug}")
        expect(flash[:success]).to eq(I18n.t("views.subforems.pages.updated"))

        expect(subforem_page.title).to eq("Updated Title")
        expect(subforem_page.slug).to eq("updated-slug")
        expect(subforem_page.description).to eq("Updated description")
        expect(subforem_page.body_markdown).to eq("# Updated Content")
      end

      it "prevents HTML/JSON/CSS in updates" do
        patch update_page_subforem_path(subforem, page_id: subforem_page.id), params: {
          page: {
            title: "Updated",
            body_markdown: "# Test",
            body_html: "<div>Should be ignored</div>",
            body_json: { test: "ignored" }.to_json
          }
        }

        subforem_page.reload
        expect(subforem_page.body_markdown).to eq("# Test")
        expect(subforem_page.body_html).to be_nil
        expect(subforem_page.body_json).to be_nil
      end

      it "maintains contained template and non-top-level path" do
        patch update_page_subforem_path(subforem, page_id: subforem_page.id), params: {
          page: {
            title: "Updated",
            template: "full_within_layout",
            is_top_level_path: true
          }
        }

        subforem_page.reload
        expect(subforem_page.template).to eq("contained")
        expect(subforem_page.is_top_level_path).to be false
      end
    end

    context "when user is subforem moderator" do
      before { sign_in moderator_user }

      it "updates a subforem page" do
        patch update_page_subforem_path(subforem, page_id: subforem_page.id), params: {
          page: {
            title: "Mod Updated",
            body_markdown: "# Mod Content"
          }
        }

        subforem_page.reload
        expect(response).to redirect_to("/page/#{subforem_page.slug}")
        expect(flash[:success]).to eq(I18n.t("views.subforems.pages.updated"))

        expect(subforem_page.title).to eq("Mod Updated")
        expect(subforem_page.body_markdown).to eq("# Mod Content")
      end

      it "can only update limited fields for top-level pages" do
        patch update_page_subforem_path(subforem, page_id: top_level_page.id), params: {
          page: {
            title: "Mod Updated Top",
            description: "Mod description"
          }
        }

        top_level_page.reload
        expect(top_level_page.title).to eq("Mod Updated Top")
        expect(top_level_page.description).to eq("Mod description")
      end
    end

    context "when page belongs to different subforem" do
      let(:other_subforem) { create(:subforem, domain: "other.com") }
      let!(:other_regular_page) do
        create(:page, subforem: other_subforem, title: "Other", slug: "other",
                      description: "Test", body_markdown: "# Test", is_top_level_path: false)
      end
      let!(:other_top_level_page) do
        create(:page, subforem: other_subforem, title: "Other Top", slug: "other-top",
                      description: "Test", body_markdown: "# Test", is_top_level_path: true)
      end

      before { sign_in moderator_user }

      it "prevents updating regular pages from other subforems" do
        patch update_page_subforem_path(subforem, page_id: other_regular_page.id), params: {
          page: { title: "Hacked" }
        }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:error]).to eq(I18n.t("views.subforems.pages.not_found"))

        other_regular_page.reload
        expect(other_regular_page.title).to eq("Other")
      end

      it "prevents updating top-level pages from other subforems" do
        patch update_page_subforem_path(subforem, page_id: other_top_level_page.id), params: {
          page: { title: "Hacked Top Level" }
        }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:error]).to eq(I18n.t("views.subforems.pages.not_found"))

        other_top_level_page.reload
        expect(other_top_level_page.title).to eq("Other Top")
      end
    end

    context "when user is not authorized" do
      before { sign_in regular_user }

      it "returns forbidden" do
        patch update_page_subforem_path(subforem, page_id: subforem_page.id), params: {
          page: { title: "Hacked" }
        }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /subforems/:id/destroy_page/:page_id" do
    let(:subforem) { create(:subforem) }
    let!(:subforem_page) do
      create(:page, subforem: subforem, title: "To Delete", slug: "to-delete",
                    description: "Test", body_markdown: "# Test", is_top_level_path: false)
    end
    let!(:top_level_page) do
      create(:page, subforem: subforem, title: "Top Level", slug: "top-level",
                    description: "Test", body_markdown: "# Test", is_top_level_path: true)
    end

    context "when user is admin" do
      before { sign_in admin_user }

      it "deletes a subforem page" do
        expect do
          delete destroy_page_subforem_path(subforem, page_id: subforem_page.id)
        end.to change { Page.count }.by(-1)

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.pages.deleted"))
      end

      it "prevents deleting top-level pages" do
        expect do
          delete destroy_page_subforem_path(subforem, page_id: top_level_page.id)
        end.not_to change { Page.count }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:error]).to eq(I18n.t("views.subforems.pages.cannot_delete"))
      end
    end

    context "when user is subforem moderator" do
      before { sign_in moderator_user }

      it "deletes a subforem page" do
        expect do
          delete destroy_page_subforem_path(subforem, page_id: subforem_page.id)
        end.to change { Page.count }.by(-1)

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:success]).to eq(I18n.t("views.subforems.pages.deleted"))
      end

      it "prevents deleting top-level pages" do
        expect do
          delete destroy_page_subforem_path(subforem, page_id: top_level_page.id)
        end.not_to change { Page.count }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:error]).to eq(I18n.t("views.subforems.pages.cannot_delete"))
      end
    end

    context "when page belongs to different subforem" do
      let(:other_subforem) { create(:subforem, domain: "other.com") }
      let!(:other_regular_page) do
        create(:page, subforem: other_subforem, title: "Other", slug: "other",
                      description: "Test", body_markdown: "# Test", is_top_level_path: false)
      end
      let!(:other_top_level_page) do
        create(:page, subforem: other_subforem, title: "Other Top", slug: "other-top",
                      description: "Test", body_markdown: "# Test", is_top_level_path: true)
      end

      before { sign_in moderator_user }

      it "prevents deleting regular pages from other subforems" do
        expect do
          delete destroy_page_subforem_path(subforem, page_id: other_regular_page.id)
        end.not_to change { Page.count }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:error]).to eq(I18n.t("views.subforems.pages.cannot_delete"))
      end

      it "prevents deleting top-level pages from other subforems" do
        expect do
          delete destroy_page_subforem_path(subforem, page_id: other_top_level_page.id)
        end.not_to change { Page.count }

        expect(response).to redirect_to(manage_subforem_path)
        expect(flash[:error]).to eq(I18n.t("views.subforems.pages.cannot_delete"))
      end
    end

    context "when user is not authorized" do
      before { sign_in regular_user }

      it "returns forbidden" do
        delete destroy_page_subforem_path(subforem, page_id: subforem_page.id)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
