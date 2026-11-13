require "rails_helper"

RSpec.describe "UserSettings" do
  let(:user) { create(:user) }

  describe "GET /settings/:tab" do
    context "when not signed-in" do
      it "redirects them to login" do
        get "/settings"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when signed-in" do
      before { sign_in user }

      it "renders various settings tabs properly" do
        Constants::Settings::TAB_LIST.each do |tab|
          get user_settings_path(tab.downcase.tr(" ", "-"))

          if tab == "Organization"
            expect(response).to have_http_status(:ok)
          else
            expect(response.body).to include("@#{user.username}")
          end
        end
      end

      it "handles unknown settings tab properly" do
        expect { get "/settings/does-not-exist" }
          .to raise_error(ActiveRecord::RecordNotFound)
      end

      it "displays Profile tab content and offers profile image removal when present", :aggregate_failures do
        get user_settings_path(:profile)

        expect(response.body).to include("User", "user[profile_image]", "user[remove_profile_image]")
        html = Nokogiri::HTML(response.body)
        checkbox = html.at_css('input[type="checkbox"][id="user[remove_profile_image]"]')
        expect(checkbox["aria-describedby"]).to eq("remove-profile-image-description")
        expect(html.css('label[for="user[remove_profile_image]"] p')).to be_empty
        expect(html.css("p#remove-profile-image-description.crayons-field__description")).to be_present
      end

      it "renders the Profile tab without the removal checkbox when there is no profile image", :aggregate_failures do
        sign_in create(:user, profile_image: nil)

        get user_settings_path(:profile)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("user[profile_image]")
        expect(response.body).not_to include("user[remove_profile_image]")
      end

      it "displays profile groups content on Profile tab" do
        profile_field = create(:profile_field)

        get user_settings_path(:profile)

        expect(response.body).to include(profile_field.profile_field_group.name)
      end

      it "displays content on Customization tab properly", :aggregate_failures do
        get user_settings_path(:customization)

        expect(response.body).to include(
          "Appearance", "Writing", "Content", "Sponsors", "Announcements", "Content Relocation",
          "theme-selector--system-theme", "theme-selector--light-theme", "theme-selector--dark-theme",
          "function applyColorMode", "prefers-color-scheme: dark",
          "disallow_subforem_reassignment", "Disable automatic relocation of my content to other subforems"
        )
      end

      it "displays content on Notifications tab properly" do
        get user_settings_path(:notifications)

        expect(response.body).to include("Email notifications", "Mobile notifications", "General notifications")
      end

      it "displays moderator notifications second on Notifications tab if trusted" do
        user.add_role(:trusted)

        get user_settings_path(:notifications)

        expect(response.body).to include("Moderator notifications")
      end

      it "displays content on Account tab properly" do
        get user_settings_path(:account)

        expect(response.body).to include("Set new password", "Account emails", "Danger Zone")
      end

      it "displays content on Billing tab properly" do
        get user_settings_path(:billing)

        expect(response.body).to include("Billing")
      end

      it "displays content on Organization tab properly" do
        get user_settings_path(:organization)

        expect(response.body).to include("Join An Organization", "Create An Organization")
      end

      it "displays Extensions tab content and renders the accessible API key form", :aggregate_failures do
        get user_settings_path(:extensions)

        expect(response.body).to include("Comment templates", "API Keys", "Manage my RSS feeds")
        html = Nokogiri::HTML(response.body)
        desc = html.at_css("p#api-key-description.crayons-field__description")
        expect(desc).to be_present
        expect(desc.text.strip).to eq(I18n.t("views.settings.extensions.api.gen.text"))

        input = html.at_css('input#api_secret_description[name="api_secret[description]"]')
        expect(input["aria-describedby"]).to eq("api-key-description")

        button = html.at_css('form[action="/users/api_secrets"] button[type="submit"]')
        expect(button[:class].split).to include("crayons-btn", "crayons-btn--secondary")
        expect(button[:class].split).not_to include("crayon-btn--secondary")
      end

      it "renders heads up dupe account message with proper param" do
        get "/settings?state=previous-registration"

        error_message = "There is an existing account authorized with that social account"
        expect(response.body).to include(error_message)
      end

      it "renders the proper response template" do
        response_template = create(:response_template, user: user)

        get user_settings_path(tab: "response-templates", id: response_template.id)

        expect(response.body).to include("Edit comment template")
      end
    end

    describe ":account" do
      let(:remove_oauth_section) { "Remove OAuth Associations" }
      let(:remove_oauth_description) { "You can remove one of your authentication methods" }
      let(:remove_oauth_instructions) { "Please add another authentication method" }
      let(:user) do
        create(:user, :without_profile, :with_identity, profile_image: nil,
                                                        identities: Authentication::Providers.available.first(2))
      end

      before do
        omniauth_mock_providers_payload
        sign_in user
      end

      it "allows users to visit the account page" do
        get user_settings_path(tab: "account")
        expect(response).to have_http_status(:ok)
      end

      it "shows the description if a user has multiple enabled identities" do
        allow(Authentication::Providers).to receive(:enabled).and_return(Authentication::Providers.available)
        providers = Authentication::Providers.available.first(2)
        allow(user).to receive(:identities).and_return(user.identities.where(provider: providers))

        get user_settings_path(tab: "account")
        expect(response.body).to include(remove_oauth_description)
        expect(response.body).not_to include(remove_oauth_instructions)
      end

      it "shows instructions how to remove an identity if a user has one enabled identity" do
        provider = Authentication::Providers.available.first
        allow(Authentication::Providers).to receive(:enabled).and_return([provider])
        allow(user).to receive(:identities).and_return(user.identities.where(provider: provider))

        get user_settings_path(tab: "account")
        expect(response.body).not_to include(remove_oauth_description)
        expect(response.body).to include(remove_oauth_instructions)
      end

      it "shows instructions how to remove an identity if a user has one enabled identity and one disabled" do
        provider = Authentication::Providers.available.first
        allow(Authentication::Providers).to receive(:enabled).and_return([provider])

        get user_settings_path(tab: "account")
        expect(response.body).not_to include(remove_oauth_description)
        expect(response.body).to include(remove_oauth_instructions)
      end

      it "hides the 'Remove OAuth' section if a user has no enabled identity" do
        allow(Authentication::Providers).to receive(:enabled).and_return([])

        get user_settings_path(tab: "account")
        expect(response.body).not_to include(remove_oauth_section)
      end
    end

    describe "connect providers accounts" do
      before do
        omniauth_mock_providers_payload
      end

      it "does not render the text for the enabled provider the user has an identity for" do
        allow(Authentication::Providers).to receive(:enabled).and_return(Authentication::Providers.available)
        user = create(:user, :with_identity, identities: [:github])

        sign_in user
        get user_settings_path

        expect(response.body).not_to include("Connect GitHub Account")
      end

      it "does not render the text for the disabled provider the user has an identity for" do
        providers = Authentication::Providers.available - %i[github]
        allow(Authentication::Providers).to receive(:enabled).and_return(providers)
        user = create(:user, :with_identity, identities: [:github])

        sign_in user
        get user_settings_path

        expect(response.body).not_to include("Connect GitHub Account")
      end

      it "renders connect text for enabled missing providers and excludes Apple", :aggregate_failures do
        allow(Authentication::Providers).to receive(:enabled).and_return(Authentication::Providers.available)
        user = create(:user, :with_identity, profile_image: nil, identities: [:twitter])

        sign_in user
        get user_settings_path

        expect(response.body).to include("Connect GitHub Account")
        expect(response.body).not_to include("Connect Apple Account")
      end

      # Identities created through the admin API carry nothing but a uid, so
      # they have no auth payload to read an email from.
      it "points a uid-only mlh identity at MLH, labels it MLH email, and offers relinking", :aggregate_failures do
        allow(Authentication::Providers).to receive(:enabled).and_return(Authentication::Providers.available)
        user = create(:user, :without_profile, profile_image: nil)
        Identity.create!(user: user, provider: "mlh", uid: "core-user-id")

        sign_in user
        get user_settings_path(tab: "account")

        expect(response.body).to include("https://www.mlh.com/account/profile", "Sign in to MLH", "MLH email",
                                         "Reconnect MLH Account")
        expect(response.body).not_to include("Please relink your", "MyMLH email", "my.mlh.io", "my.mlh.com")
      end

      it "links MLH profile settings to the MLH account profile page", :aggregate_failures do
        allow(Authentication::Providers).to receive(:enabled).and_return(Authentication::Providers.available)
        user = create(:user, :without_profile, :with_identity, profile_image: nil, identities: %i[github mlh])

        sign_in user
        get user_settings_path(tab: "account")

        expect(response.body).to include('href="https://www.mlh.com/account/profile">MLH profile settings</a>')
        expect(response.body).not_to include("my.mlh.io/oauth/applications")
      end

      it "does not offer a relink for an mlh identity that has a payload", :aggregate_failures do
        allow(Authentication::Providers).to receive(:enabled).and_return(Authentication::Providers.available)
        user = create(:user, :without_profile, :with_identity, profile_image: nil, identities: [:mlh])

        sign_in user
        get user_settings_path(tab: "account")

        expect(response.body).not_to include("Reconnect MLH Account")
        expect(response.body).not_to include("Connect MLH Account")
      end
    end

    describe "GitHub repositories" do
      it "renders the repositories container if the user has authenticated through GitHub" do
        omniauth_mock_providers_payload
        allow(Authentication::Providers).to receive(:enabled).and_return(Authentication::Providers.available)
        user = create(:user, :without_profile, :with_identity, profile_image: nil, identities: [:github])

        sign_in user
        get user_settings_path(:extensions)

        expect(response.body).to include("github-repos-container")
      end

      it "does not render anything if the user has not authenticated through GitHub" do
        sign_in user
        get user_settings_path(:extensions)

        expect(response.body).not_to include("github-repos-container")
      end
    end
  end

  describe "PUT /update/:id" do
    before { sign_in user }

    it "updates profile_updated_at" do
      user.update_column(:profile_updated_at, 2.weeks.ago)
      put "/users/#{user.id}", params: { user: { tab: "profile", username: "new_username" } }
      expect(user.reload.profile_updated_at).to be > 2.minutes.ago
    end

    it "updates the users announcement display preferences (in both users and user_settings tables)" do
      expect(user.setting.display_announcements).to be(true)

      expect do
        put users_settings_path(user.setting.id), params: { users_setting: { display_announcements: 0 } }
      end.to change { user.setting.reload.display_announcements }.from(true).to(false)

      expect(user.setting.reload.display_announcements).to be(false)
    end

    it "updates the users subforem reassignment preferences and allows re-enabling it", :aggregate_failures do
      expect(user.setting.disallow_subforem_reassignment).to be(false)

      expect do
        put users_settings_path(user.setting.id), params: { users_setting: { disallow_subforem_reassignment: 1 } }
      end.to change { user.setting.reload.disallow_subforem_reassignment }.from(false).to(true)

      expect do
        put users_settings_path(user.setting.id), params: { users_setting: { disallow_subforem_reassignment: 0 } }
      end.to change { user.setting.reload.disallow_subforem_reassignment }.from(true).to(false)
    end

    it "updates the users theme to system_theme and keeps an explicit theme choice", :aggregate_failures do
      expect do
        put users_settings_path(user.setting.id), params: { users_setting: { config_theme: "system_theme" } }
      end.to change { user.setting.reload.config_theme }.from("light_theme").to("system_theme")

      expect do
        put users_settings_path(user.setting.id), params: { users_setting: { config_theme: "dark_theme" } }
      end.to change { user.setting.reload.config_theme }.from("system_theme").to("dark_theme")
    end

    it "shows the correct checkbox state for subforem reassignment setting" do
      user.setting.update!(disallow_subforem_reassignment: true)

      get user_settings_path(:customization)

      expect(response.body).to include('checked="checked"')
    end

    it "updates username to too short username" do
      put "/users/#{user.id}", params: { user: { tab: "profile", username: "h" } }
      expect(response.body).to include("Username is too short")
    end

    it "returns error message if user can't be saved" do
      put "/users/#{user.id}", params: { user: { password: "1", password_confirmation: "1" } }

      expect(flash[:error]).to include("Password is too short")
    end

    it "returns an error message if the passwords do not match" do
      put "/users/#{user.id}", params: { user: { password: "asdfghjk", password_confirmation: "qwertyui" } }

      expect(flash[:error]).to include("Password doesn't match password confirmation")
    end

    context "when requesting an export of the articles" do
      def send_request(export_requested: true)
        put user_path(user.id), params: { user: { tab: :account, export_requested: export_requested } }
      end

      it "updates export_requested, sets flash, updates the account page, and sends an email", :aggregate_failures do
        allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)

        send_request
        expect(user.reload.export_requested).to be(true)
        expect(flash[:settings_notice]).to include("The export will be emailed to you shortly.")

        follow_redirect!
        expect(response.body).not_to include("Request an export of your posts")
        expect(response.body).to include("You have recently requested an export")

        expect do
          sidekiq_perform_enqueued_jobs(only: ExportContentWorker)
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "does not send an email if there was no request" do
        sidekiq_perform_enqueued_jobs(only: ExportContentWorker) do
          expect { send_request(export_requested: false) }.not_to(change { ActionMailer::Base.deliveries.count })
        end
      end
    end

    context "when requesting a fetch of the feed", vcr: { cassette_name: "feeds_import_medium_vaidehi" } do
      let(:feed_url) { "https://medium.com/feed/@vaidehijoshi" }
      let(:user) do
        u = create(:user, :without_profile, profile_image: nil)
        u.setting.update(feed_url: feed_url)
        u
      end

      it "invokes Feeds::ImportArticlesWorker" do
        allow(Feeds::ImportArticlesWorker).to receive(:perform_async).with(user.id)

        put users_settings_path(user.setting.id), params: { users_setting: { feed_url: feed_url } }

        expect(Feeds::ImportArticlesWorker).to have_received(:perform_async).with(user.id)
      end
    end
  end

  describe "DELETE /users/remove_identity" do
    let(:provider) { Authentication::Providers.available.first }

    context "when user has multiple identities" do
      let(:user) do
        identities = Authentication::Providers.available.first(2) | %i[github twitter]
        create(:user, :without_profile, :with_identity, profile_image: nil, identities: identities)
      end

      before do
        omniauth_mock_providers_payload
        allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
        sign_in user
      end

      it "removes the identity, clears username, updates timestamp, and redirects with notice", :aggregate_failures do
        original_profile_updated_at = user.profile_updated_at
        auth_provider = Authentication::Providers.get!(provider)

        expect do
          delete users_remove_identity_path, params: { provider: provider }
        end.to change(user.identities, :count).by(-1)

        expect(user.identities.map(&:provider)).not_to include(provider)
        expect(user.public_send(:"#{provider}_username")).to be_nil
        expect(user.profile_updated_at.to_i).to be > original_profile_updated_at.to_i
        expect(response).to redirect_to("/settings/account")
        expect(flash[:settings_notice]).to eq("Your #{auth_provider.official_name} account was successfully removed.")
      end

      it "redirects the user with an error if the corresponding provider has been since disabled" do
        providers = Authentication::Providers.available - [provider]
        allow(Authentication::Providers).to receive(:enabled).and_return(providers)
        delete users_remove_identity_path, params: { provider: provider }
        expect(response).to redirect_to("/settings/account")

        error =
          "An error occurred. Please try again or send an email to: #{ForemInstance.contact_email}"
        expect(flash[:error]).to eq(error)
      end

      it "does not show the 'Remove OAuth' section afterwards if only one identity remains" do
        providers = Authentication::Providers.available.first(2)
        allow(user).to receive(:identities).and_return(user.identities.where(provider: providers))

        delete users_remove_identity_path, params: { provider: providers.first }
        expect(response.body).not_to include("Remove OAuth Associations")
      end

      it "does not remove GitHub repositories if the removed identity is not GitHub" do
        create(:github_repo, user: user)

        expect do
          delete users_remove_identity_path, params: { provider: :twitter }
        end.not_to change(user.github_repos, :count)
      end

      it "removes GitHub repositories if the removed identity is GitHub" do
        repo = create(:github_repo, user: user)

        expect do
          delete users_remove_identity_path, params: { provider: :github }
        end.to change(user.github_repos, :count).by(-1)

        expect(GithubRepo.exists?(id: repo.id)).to be(false)
      end
    end

    # Users won't be able to do this via the view, but in case they hit the route somehow...
    context "when user has only one identity" do
      let(:user) { create(:user, :without_profile, :with_identity, profile_image: nil, identities: [provider]) }

      before do
        omniauth_mock_providers_payload
        sign_in user
      end

      it "does not delete any identities and redirects with flash error", :aggregate_failures do
        expect do
          delete users_remove_identity_path, params: { provider: provider }
        end.not_to change(user.identities, :count)

        error =
          "An error occurred. Please try again or send an email to: #{ForemInstance.contact_email}"
        expect(flash[:error]).to eq(error)
        expect(response).to redirect_to(user_settings_path(:account))
      end
    end
  end
end
