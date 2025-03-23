require "rails_helper"

RSpec.describe "Notifications::Reads", type: :request do
  # Helper method to create a follow notification
  def create_follow_notifications(user, following_user)
    follow_instance = following_user.follow(user)
    Notification.send_new_follower_notification_without_delay(follow_instance)
  end

  describe "POST /notifications/reads" do
    context "when using session-based authentication" do
      let(:user)           { create(:user) }
      let(:following_user) { create(:user) }

      before { sign_in user }

      it "marks notifications as read" do
        create_follow_notifications(user, following_user)
        expect(user.notifications.unread.count).to eq(1)

        post "/notifications/reads"

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("read")
        expect(user.notifications.unread.count).to eq(0)
      end

      it "marks both personal and organization notifications as read" do
        # Create an org admin with an organization
        org_admin = create(:user, :org_admin)
        org       = org_admin.organizations.first

        # Create notifications for both the organization and the org admin
        create_follow_notifications(org, following_user)
        create_follow_notifications(org_admin, following_user)
        expect(org_admin.notifications.unread.count).to eq(1)
        expect(org.notifications.unread.count).to eq(1)

        # Sign in the organization admin
        sign_in org_admin

        # Send the org_id so that both notifications are marked as read
        post "/notifications/reads", params: { org_id: org.id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("read")
        expect(org_admin.notifications.unread.count).to eq(0)
        expect(org.notifications.unread.count).to eq(0)
      end
    end

    context "when using token-based authentication" do
      let(:user)           { create(:user) }
      let(:following_user) { create(:user) }
      let(:token)          { "valid_token" }
      let(:headers)        { { "Authorization" => "Bearer #{token}" } }

      before do
        # Stub the token decoder so that a valid token returns a payload with the user's id.
        allow_any_instance_of(ApplicationController)
          .to receive(:decode_auth_token)
          .with(token)
          .and_return({ "user_id" => user.id })
        # Ensure no session-based authentication interferes
        sign_out(user) if respond_to?(:sign_out)
      end

      it "marks notifications as read" do
        create_follow_notifications(user, following_user)
        expect(user.notifications.unread.count).to eq(1)

        post "/notifications/reads", headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("read")
        expect(user.notifications.unread.count).to eq(0)
      end

      context "with an invalid token" do
        let(:token)   { "invalid_token" }
        let(:headers) { { "Authorization" => "Bearer #{token}" } }

        before do
          allow_any_instance_of(ApplicationController)
            .to receive(:decode_auth_token)
            .with(token)
            .and_return(nil)
        end

        it "returns an empty response" do
          post "/notifications/reads", headers: headers

          expect(response).to have_http_status(:no_content)
          expect(response.body).to eq("")
        end
      end
    end

    context "when no current user is present" do
      it "returns an empty response" do
        post "/notifications/reads"

        expect(response).to have_http_status(:no_content)
        expect(response.body).to eq("")
      end
    end
  end
end
