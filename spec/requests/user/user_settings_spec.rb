require "rails_helper"

RSpec.describe "UserSettings", type: :request do
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

          expect(response.body).to include("Settings for")
        end
      end

      it "handles unknown settings tab properly" do
        expect { get "/settings/does-not-exist" }
          .to raise_error(ActiveRecord::RecordNotFound)
      end

      it "displays content on Profile tab properly" do
        get user_settings_path(:profile)

        expect(response.body).to include("User")
      end

      it "displays profile groups content on Profile tab" do
        profile_field = create(:profile_field)

        get user_settings_path(:profile)

        expect(response.body).to include(profile_field.profile_field_group.name)
      end

      it "displays content on Customization tab properly" do
        get user_settings_path(:customization)

        expect(response.body).to include("Appearance", "Writing", "Content", "Sponsors", "Announcements")
      end

      it "displays content on Notifications tab properly" do
        get user_settings_path(:notifications)

        expect(response.body).to include("Email notifications", "Mobile notifications", "General notifications")
      end

      it "displays moderator notifications secons on Notifications tab if trusted" do
        user.add_role(:trusted)

        get user_settings_path(:notifications)

        expect(response.body).to include("Moderator notifications")
      end

      it "displays content on Account tab properly" do
        get user_settings_path(:account)

        expect(response.body).to include("Set new password", "Account emails", "API Keys", "Danger Zone")
      end

      it "displays content on Billing tab properly" do
        get user_settings_path(:billing)

        expect(response.body).to include("Billing")
      end

      it "displays content on Organization tab properly" do
        get user_settings_path(:organization)

        expect(response.body).to include("Join An Organization", "Create An Organization")
      end

      it "displays content on Extensions tab properly" do
        get user_settings_path(:extensions)

        feed_section = "Publishing to #{Settings::Community.community_name} from RSS"
        stackbit_section = "Generate a personal blog from your #{Settings::Community.community_name} posts"
        titles = ["Comment templates", "Connect settings", feed_section, "Web monetization", stackbit_section]
        expect(response.body).to include(*titles)
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
      let(:user) { create(:user, :with_identity) }

      before do
        omniauth_mock_providers_payload
        sign_in user
      end

      it "allows users to visit the account page" do
        get user_settings_path(tab: "account")
        expect(response).to have_http_status(:ok)
      end

      it "shows the 'Remove OAuth' section if a user has multiple enabled identities" do
        allow(Authentication::Providers).to receive(:enabled).and_return(Authentication::Providers.available)
        providers = Authentication::Providers.available.first(2)
        allow(user).to receive(:identities).and_return(user.identities.where(provider: providers))

        get user_settings_path(tab: "account")
        expect(response.body).to include(remove_oauth_section)
      end

      it "hides the 'Remove OAuth' section if a user has one enabled identity" do
        provider = Authentication::Providers.available.first
        allow(Authentication::Providers).to receive(:enabled).and_return([provider])
        allow(user).to receive(:identities).and_return(user.identities.where(provider: provider))

        get user_settings_path(tab: "account")
        expect(response.body).not_to include(remove_oauth_section)
      end

      it "hides the 'Remove OAuth' section if a user has one enabled identity and one disabled" do
        provider = Authentication::Providers.available.first
        allow(Authentication::Providers).to receive(:enabled).and_return([provider])

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

      it "renders the text for the enabled provider the user has no identity for" do
        allow(Authentication::Providers).to receive(:enabled).and_return(Authentication::Providers.available)
        user = create(:user, :with_identity, identities: [:twitter])

        sign_in user
        get user_settings_path

        expect(response.body).to include("Connect GitHub Account")
      end
    end

    describe "GitHub repositories" do
      it "renders the repositories container if the user has authenticated through GitHub" do
        allow(Authentication::Providers).to receive(:enabled).and_return(Authentication::Providers.available)
        user = create(:user, :with_identity, identities: [:github])

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

  describe "GET /settings/profile" do
    before { sign_in user }

    context "when user has profile image" do
      it "displays profile image upload input" do
        get user_settings_path(:profile)

        expect(response.body).to include("user[profile_image]")
      end
    end

    context "when user does not have a profile image" do
      let(:user) { create(:user, profile_image: nil) }

      it "displays profile image upload input" do
        get user_settings_path(:profile)

        expect(response.body).to include("user[profile_image]")
      end
    end
  end

  describe "PUT /update/:id" do
    before { sign_in user }

    it "updates summary" do
      put "/users/#{user.id}", params: { user: { tab: "profile", summary: "Hello new summary" } }
      expect(user.summary).to eq("Hello new summary")
    end

    it "updates profile_updated_at" do
      user.update_column(:profile_updated_at, 2.weeks.ago)
      put "/users/#{user.id}", params: { user: { tab: "profile", summary: "Hello new summary" } }
      expect(user.reload.profile_updated_at).to be > 2.minutes.ago
    end

    it "disables reaction notifications (in both users and notification_settings tables)" do
      expect(user.notification_setting.reaction_notifications).to be(true)

      expect do
        put "/users/#{user.id}", params: { user: { tab: "notifications", reaction_notifications: 0 } }
      end.to change { user.reload.reaction_notifications }.from(true).to(false)

      expect(user.notification_setting.reload.reaction_notifications).to be(false)
    end

    it "enables community-success notifications" do
      put "/users/#{user.id}", params: { user: { tab: "notifications", mod_roundrobin_notifications: 1 } }
      expect(user.reload.subscribed_to_mod_roundrobin_notifications?).to be(true)
    end

    it "updates the users announcement display preferences (in both users and user_settings tables)" do
      expect(user.setting.display_announcements).to be(true)

      expect do
        put "/users/#{user.id}", params: { user: { tab: "misc", display_announcements: 0 } }
      end.to change { user.reload.display_announcements }.from(true).to(false)

      expect(user.setting.reload.display_announcements).to be(false)
    end

    it "disables community-success notifications" do
      put "/users/#{user.id}", params: { user: { tab: "notifications", mod_roundrobin_notifications: 0 } }
      expect(user.reload.subscribed_to_mod_roundrobin_notifications?).to be(false)
    end

    it "can toggle welcome notifications" do
      put "/users/#{user.id}", params: { user: { tab: "notifications", welcome_notifications: 0 } }
      expect(user.reload.subscribed_to_welcome_notifications?).to be(false)

      put "/users/#{user.id}", params: { user: { tab: "notifications", welcome_notifications: 1 } }
      expect(user.reload.subscribed_to_welcome_notifications?).to be(true)
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

      it "updates export_requested flag" do
        send_request
        expect(user.reload.export_requested).to be(true)
      end

      it "displays a flash with a reminder for the user to expect an email" do
        send_request
        expect(flash[:settings_notice]).to include("The export will be emailed to you shortly.")
      end

      it "hides the checkbox" do
        send_request
        follow_redirect!
        expect(response.body).not_to include("Request an export of your posts")
      end

      it "tells the user they recently requested an export" do
        send_request
        follow_redirect!
        expect(response.body).to include("You have recently requested an export")
      end

      it "sends an email" do
        expect do
          sidekiq_perform_enqueued_jobs do
            send_request
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "does not send an email if there was no request" do
        sidekiq_perform_enqueued_jobs do
          expect { send_request(export_requested: false) }.not_to(change { ActionMailer::Base.deliveries.count })
        end
      end
    end

    context "when requesting a fetch of the feed", vcr: { cassette_name: "feeds_import_medium_vaidehi" } do
      let(:feed_url) { "https://medium.com/feed/@vaidehijoshi" }
      let(:user) { create(:user, feed_url: feed_url) }

      it "invokes Feeds::ImportArticlesWorker" do
        allow(Feeds::ImportArticlesWorker).to receive(:perform_async).with(nil, user.id)

        put user_path(user.id), params: { user: { feed_url: feed_url } }

        expect(Feeds::ImportArticlesWorker).to have_received(:perform_async).with(nil, user.id)
      end
    end
  end

  describe "DELETE /users/remove_identity" do
    let(:provider) { Authentication::Providers.available.first }

    context "when user has multiple identities" do
      let(:user) { create(:user, :with_identity) }

      before do
        omniauth_mock_providers_payload
        allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
        sign_in user
      end

      it "removes the correct identity" do
        expect do
          delete users_remove_identity_path, params: { provider: provider }
        end.to change(user.identities, :count).by(-1)

        expect(user.identities.map(&:provider)).not_to include(provider)
      end

      it "empties their associated username" do
        delete users_remove_identity_path, params: { provider: provider }

        expect(user.public_send("#{provider}_username")).to be(nil)
      end

      it "updates the profile_updated_at timestamp" do
        original_profile_updated_at = user.profile_updated_at
        delete users_remove_identity_path, params: { provider: provider }
        expect(user.profile_updated_at.to_i).to be > original_profile_updated_at.to_i
      end

      it "redirects successfully to /settings/account" do
        delete users_remove_identity_path, params: { provider: provider }
        expect(response).to redirect_to("/settings/account")
      end

      it "renders a successful response message" do
        delete users_remove_identity_path, params: { provider: provider }
        auth_provider = Authentication::Providers.get!(provider)

        expected_notice = "Your #{auth_provider.official_name} account was successfully removed."
        expect(flash[:settings_notice]).to eq(expected_notice)
      end

      it "redirects the user with an error if the corresponding provider has been since disabled" do
        providers = Authentication::Providers.available - [provider]
        allow(Authentication::Providers).to receive(:enabled).and_return(providers)
        delete users_remove_identity_path, params: { provider: provider }
        expect(response).to redirect_to("/settings/account")

        error =
          "An error occurred. Please try again or send an email to: #{Settings::General.email_addresses[:contact]}"
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
      let(:user) { create(:user, :with_identity, identities: [provider]) }

      before do
        sign_in user
      end

      it "sets the proper flash error message" do
        delete users_remove_identity_path, params: { provider: provider }

        error =
          "An error occurred. Please try again or send an email to: #{Settings::General.email_addresses[:contact]}"
        expect(flash[:error]).to eq(error)
      end

      it "does not delete any identities" do
        expect do
          delete users_remove_identity_path, params: { provider: provider }
        end.not_to change(user.identities, :count)
      end

      it "redirects successfully to the Settings-Account page" do
        delete users_remove_identity_path, params: { provider: provider }
        expect(response).to redirect_to(user_settings_path(:account))
      end
    end
  end
end
