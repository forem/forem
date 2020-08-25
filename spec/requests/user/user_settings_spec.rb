require "rails_helper"

RSpec.describe "UserSettings", type: :request do
  let(:user) { create(:user, twitch_username: nil) }

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
        %w[organization misc account ux].each do |tab|
          get "/settings/#{tab}"
          expect(response.body).to include("Settings for")
        end
      end

      it "handles unknown settings tab properly" do
        expect { get "/settings/does-not-exist" }
          .to raise_error(ActiveRecord::RecordNotFound)
      end

      it "displays content on ux tab properly" do
        get "/settings/ux"
        expect(response.body).to include("Style Customization")
      end

      it "displays content on misc tab properly" do
        get "/settings/misc"
        expect(response.body).to include("Connect", "Languages", "Sponsors", "Announcements", "Export Content")
      end

      it "displays content on RSS tab properly" do
        get "/settings/publishing-from-rss"
        title = "Publishing to #{SiteConfig.community_name} from RSS"
        expect(response.body).to include(title)
      end

      it "renders heads up dupe account message with proper param" do
        get "/settings?state=previous-registration"
        error_message = "There is an existing account authorized with that social account"
        expect(response.body).to include error_message
      end

      it "renders the proper response template" do
        response_template = create(:response_template, user: user)
        get user_settings_path(tab: "response-templates", id: response_template.id)
        expect(response.body).to include "Editing a response template"
      end
    end

    describe ":account" do
      let(:ghost_account_message) { "If you would like to keep your content under the" }
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

      it "does not render the ghost account email option if the user has no content" do
        get user_settings_path(tab: "account")
        expect(response.body).not_to include(ghost_account_message)
      end

      it "does render the ghost account email option if the user has content" do
        create(:article, user: user)
        user.update(articles_count: 1)

        get user_settings_path(tab: "account")

        expect(response.body).to include(ghost_account_message)
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
        get "/settings"

        expect(response.body).not_to include("Connect GitHub Account")
      end

      it "does not render the text for the disabled provider the user has an identity for" do
        providers = Authentication::Providers.available - %i[github]
        allow(Authentication::Providers).to receive(:enabled).and_return(providers)
        user = create(:user, :with_identity, identities: [:github])

        sign_in user
        get "/settings"

        expect(response.body).not_to include("Connect GitHub Account")
      end

      it "renders the text for the enabled provider the user has no identity for" do
        allow(Authentication::Providers).to receive(:enabled).and_return(Authentication::Providers.available)
        user = create(:user, :with_identity, identities: [:twitter])

        sign_in user
        get "/settings"

        expect(response.body).to include("Connect GitHub Account")
      end
    end

    describe ":integrations" do
      it "renders the repositories container if the user has authenticated through GitHub" do
        user = create(:user, :with_identity, identities: [:github])
        sign_in user

        get user_settings_path(tab: :integrations)
        expect(response.body).to include("github-repos-container")
      end

      it "does not render anything if the user has not authenticated through GitHub" do
        sign_in user

        get user_settings_path(tab: :integrations)
        expect(response.body).not_to include("github-repos-container")
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

    it "disables reaction notifications" do
      put "/users/#{user.id}", params: { user: { tab: "notifications", reaction_notifications: 0 } }
      expect(user.reload.reaction_notifications).to be(false)
    end

    it "enables community-success notifications" do
      put "/users/#{user.id}", params: { user: { tab: "notifications", mod_roundrobin_notifications: 1 } }
      expect(user.reload.mod_roundrobin_notifications).to be(true)
    end

    it "updates the users announcement display preferences" do
      expect do
        put "/users/#{user.id}", params: { user: { tab: "misc", display_announcements: 0 } }
      end.to change { user.reload.display_announcements }.from(true).to(false)
    end

    it "disables community-success notifications" do
      put "/users/#{user.id}", params: { user: { tab: "notifications", mod_roundrobin_notifications: 0 } }
      expect(user.reload.mod_roundrobin_notifications).to be(false)
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

    it "returns error if Profile image is too large" do
      profile_image = fixture_file_upload("files/large_profile_img.jpg", "image/jpeg")
      put "/users/#{user.id}", params: { user: { tab: "profile", profile_image: profile_image } }
      expect(response.body).to include("Profile image File size should be less than 2 MB")
    end

    it "returns error if Profile image file name is too long" do
      profile_image = fixture_file_upload("files/800x600.png", "image/png")
      allow(profile_image).to receive(:original_filename).and_return("#{'a_very_long_filename' * 15}.png")

      put "/users/#{user.id}", params: { user: { tab: "profile", profile_image: profile_image } }

      expect(response).to have_http_status(:bad_request)
    end

    it "returns error if Profile image is not a file" do
      profile_image = "A String"
      put "/users/#{user.id}", params: { user: { tab: "profile", profile_image: profile_image } }

      expect(response).to have_http_status(:bad_request)
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
        put "/users/#{user.id}", params: {
          user: { tab: "misc", export_requested: export_requested }
        }
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
  end

  describe "POST /users/update_twitch_username" do
    before { sign_in user }

    it "updates twitch username" do
      post "/users/update_twitch_username", params: { user: { twitch_username: "anna_lightalloy" } }
      user.reload
      expect(user.twitch_username).to eq("anna_lightalloy")
    end

    it "redirects after updating" do
      post "/users/update_twitch_username", params: { user: { twitch_username: "anna_lightalloy" } }
      expect(response).to redirect_to "/settings/integrations"
    end

    it "schedules the job while updating" do
      sidekiq_assert_enqueued_with(job: Streams::TwitchWebhookRegistrationWorker, args: [user.id]) do
        post "/users/update_twitch_username", params: { user: { twitch_username: "anna_lightalloy" } }
      end
    end

    it "removes twitch_username" do
      user.update_column(:twitch_username, "robot")
      post "/users/update_twitch_username", params: { user: { twitch_username: "" } }
      user.reload
      expect(user.twitch_username).to be_nil
    end

    it "doesn't schedule the job when removing" do
      sidekiq_assert_no_enqueued_jobs(only: Streams::TwitchWebhookRegistrationWorker) do
        post "/users/update_twitch_username", params: { user: { twitch_username: "" } }
      end
    end

    it "doesn't schedule the job when saving the same twitch username" do
      user.update_column(:twitch_username, "robot")
      sidekiq_assert_no_enqueued_jobs(only: Streams::TwitchWebhookRegistrationWorker) do
        post "/users/update_twitch_username", params: { user: { twitch_username: "robot" } }
      end
    end
  end

  describe "POST /users/update_language_settings" do
    before { sign_in user }

    it "updates language settings" do
      post "/users/update_language_settings", params: { user: { preferred_languages: %w[ja es] } }
      user.reload
      expect(user.language_settings["preferred_languages"]).to eq(%w[ja es])
    end

    it "keeps the estimated_default_language" do
      user.update_column(:language_settings, estimated_default_language: "ru", preferred_languages: %w[en es])
      post "/users/update_language_settings", params: { user: { preferred_languages: %w[it en] } }
      user.reload
      expect(user.language_settings["estimated_default_language"]).to eq("ru")
    end

    it "doesn't set non-existent languages" do
      user.update_column(:language_settings, estimated_default_language: "ru", preferred_languages: %w[en es])
      post "/users/update_language_settings", params: { user: { preferred_languages: %w[it en blah] } }
      user.reload
      expect(user.language_settings["preferred_languages"].sort).to eq(%w[en it])
    end
  end

  describe "DELETE /users/remove_identity" do
    let(:provider) { Authentication::Providers.available.first }

    context "when user has multiple identities" do
      let(:user) { create(:user, :with_identity) }

      before do
        omniauth_mock_providers_payload
        sign_in user
      end

      it "removes the correct identity" do
        expect do
          delete "/users/remove_identity", params: { provider: provider }
        end.to change(user.identities, :count).by(-1)

        expect(user.identities.map(&:provider)).not_to include(provider)
      end

      it "empties their associated username" do
        delete "/users/remove_identity", params: { provider: provider }

        expect(user.public_send("#{provider}_username")).to be(nil)
      end

      it "updates the profile_updated_at timestamp" do
        original_profile_updated_at = user.profile_updated_at
        delete "/users/remove_identity", params: { provider: provider }
        expect(user.profile_updated_at.to_i).to be > original_profile_updated_at.to_i
      end

      it "redirects successfully to /settings/account" do
        delete "/users/remove_identity", params: { provider: provider }
        expect(response).to redirect_to("/settings/account")
      end

      it "renders a successful response message" do
        delete "/users/remove_identity", params: { provider: provider }
        auth_provider = Authentication::Providers.get!(provider)

        expected_notice = "Your #{auth_provider.official_name} account was successfully removed."
        expect(flash[:settings_notice]).to eq(expected_notice)
      end

      it "redirects the user with an error if the corresponding provider has been since disabled" do
        providers = Authentication::Providers.available - [provider]
        allow(Authentication::Providers).to receive(:enabled).and_return(providers)
        delete "/users/remove_identity", params: { provider: provider }
        expect(response).to redirect_to("/settings/account")

        error = "An error occurred. Please try again or send an email to: #{SiteConfig.email_addresses[:default]}"
        expect(flash[:error]).to eq(error)
      end

      it "does not show the 'Remove OAuth' section afterwards if only one identity remains" do
        providers = Authentication::Providers.available.first(2)
        allow(user).to receive(:identities).and_return(user.identities.where(provider: providers))

        delete "/users/remove_identity", params: { provider: providers.first }
        expect(response.body).not_to include("Remove OAuth Associations")
      end
    end

    # Users won't be able to do this via the view, but in case they hit the route somehow...
    context "when user has only one identity" do
      let(:user) { create(:user, :with_identity, identities: [provider]) }

      before do
        sign_in user
      end

      it "sets the proper flash error message" do
        delete "/users/remove_identity", params: { provider: provider }

        error = "An error occurred. Please try again or send an email to: #{SiteConfig.email_addresses[:default]}"
        expect(flash[:error]).to eq(error)
      end

      it "does not delete any identities" do
        expect do
          delete "/users/remove_identity", params: { provider: provider }
        end.not_to change(user.identities, :count)
      end

      it "redirects successfully to /settings/account" do
        delete "/users/remove_identity", params: { provider: provider }
        expect(response).to redirect_to("/settings/account")
      end
    end
  end
end
