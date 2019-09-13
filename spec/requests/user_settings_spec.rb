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
        %w[organization misc account].each do |tab|
          get "/settings/#{tab}"
          expect(response.body).to include("Settings for")
        end
      end

      it "handles unknown settings tab properly" do
        expect { get "/settings/does-not-exist" }.
          to raise_error(ActiveRecord::RecordNotFound)
      end

      it "allows users to visit the account page" do
        get "/settings/account"
        expect(response.body).to include("Danger Zone")
      end

      it "renders heads up dupe account message with proper param" do
        get "/settings?state=previous-registration"
        error_message = "There is an existing account authorized with that social account"
        expect(response.body).to include error_message
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

    it "updates username to too short username" do
      put "/users/#{user.id}", params: { user: { tab: "profile", username: "h" } }
      expect(response.body).to include("Username is too short")
    end

    it "returns error if Profile image is too large" do
      profile_image = fixture_file_upload("files/large_profile_img.jpg", "image/jpeg")
      put "/users/#{user.id}", params: { user: { tab: "profile", profile_image: profile_image } }
      expect(response.body).to include("Profile image File size should be less than 2 MB")
    end

    context "when requesting an export of the articles" do
      def send_request(flag = true)
        put "/users/#{user.id}", params: {
          user: { tab: "misc", export_requested: flag }
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
        perform_enqueued_jobs do
          expect { send_request }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end

      it "does not send an email if there was no request" do
        perform_enqueued_jobs do
          expect { send_request(false) }.not_to(change { ActionMailer::Base.deliveries.count })
        end
      end
    end
  end

  describe "POST /users/update_twitch_username" do
    before { login_as user }

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
      expect do
        post "/users/update_twitch_username", params: { user: { twitch_username: "anna_lightalloy" } }
      end.to have_enqueued_job(Streams::TwitchWebhookRegistrationJob).exactly(:once).with(user.id)
    end

    it "removes twitch_username" do
      user.update_column(:twitch_username, "robot")
      post "/users/update_twitch_username", params: { user: { twitch_username: "" } }
      user.reload
      expect(user.twitch_username).to be_nil
    end

    it "doesn't schedule the job when removing" do
      expect do
        post "/users/update_twitch_username", params: { user: { twitch_username: "" } }
      end.not_to have_enqueued_job(Streams::TwitchWebhookRegistrationJob)
    end

    it "doesn't schedule the job when saving the same twitch username" do
      user.update_column(:twitch_username, "robot")
      expect do
        post "/users/update_twitch_username", params: { user: { twitch_username: "robot" } }
      end.not_to have_enqueued_job(Streams::TwitchWebhookRegistrationJob)
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

  describe "DELETE /users/remove_association" do
    context "when user has two identities" do
      let(:user) { create(:user, :two_identities) }

      before { sign_in user }

      it "brings the identity count to 1" do
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(user.identities.count).to eq 1
      end

      it "removes the correct identity" do
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(user.identities.first.provider).to eq "github"
      end

      it "removes their associated username" do
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(user.twitter_username).to eq nil
      end

      it "touches the profile_updated_at timestamp" do
        original_profile_updated_at = user.profile_updated_at
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(user.profile_updated_at).to be > original_profile_updated_at
      end

      it "redirects successfully to /settings/account" do
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(response).to redirect_to "/settings/account"
      end

      it "renders a successful response message" do
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(flash[:settings_notice]).to eq "Your Twitter account was successfully removed."
      end

      it "does not show the Remove OAuth section afterward" do
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(response.body).not_to include "Remove OAuth Associations"
      end
    end

    # Users won't be able to do this via the view, but in case they hit the route somehow...
    context "when user has only one identity" do
      before { sign_in user }

      it "sets the proper error message" do
        delete "/users/remove_association", params: { provider: "github" }
        expect(flash[:error]).
          to eq "An error occurred. Please try again or send an email to: yo@dev.to"
      end

      it "does not delete any identities" do
        original_identity_count = user.identities.count
        delete "/users/remove_association", params: { provider: "github" }
        expect(user.identities.count).to eq original_identity_count
      end

      it "redirects successfully to /settings/account" do
        delete "/users/remove_association", params: { provider: "github" }
        expect(response).to redirect_to "/settings/account"
      end
    end
  end

  describe "DELETE /users/destroy" do
    context "when user has no articles or comments" do
      before do
        sign_in user
        delete "/users/destroy"
      end

      it "destroys the user" do
        expect(user.persisted?).to eq false
      end

      it "sends an email to the user" do
        expect(EmailMessage.last.to).to eq user.email
      end

      it "signs out the user" do
        expect(controller.current_user).to eq nil
      end

      it "redirects successfully to the home page" do
        expect(response).to redirect_to "/"
      end
    end

    context "when users are not allowed to destroy" do
      let(:user_with_article) { create(:user, :with_article) }
      let(:user_with_comment) { create(:user, :with_only_comment) }
      let(:user_with_article_and_comment) { create(:user, :with_article_and_comment) }
      let(:users) { [user_with_article, user_with_comment, user_with_article_and_comment] }

      it "does not allow invalid users to delete their account" do
        users.each do |user|
          sign_in user
          delete "/users/destroy"
          expect(user.persisted?).to eq true
        end
      end

      it "redirects successfully to /settings/account" do
        users.each do |user|
          sign_in user
          delete "/users/destroy"
          expect(response).to redirect_to "/settings/account"
        end
      end

      it "shows the proper error message after redirecting" do
        users.each do |user|
          sign_in user
          delete "/users/destroy"
          expect(flash[:error]).to eq "An error occurred. Try requesting an account deletion below."
        end
      end
    end
  end
end
