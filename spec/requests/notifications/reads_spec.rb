require "rails_helper"

RSpec.describe "Notifications::Reads" do
  def create_follow_notifications(user, following_user)
    follow_instance = following_user.follow(user)
    Notification.send_new_follower_notification_without_delay(follow_instance)
  end

  describe "POST /notifications/reads" do
    let(:user) { create(:user) }
    let(:following_user) { create(:user) }

    context "when use is signed in" do
      before { sign_in user }

      it "marks notifications as read" do
        create_follow_notifications(user, following_user)
        expect(user.notifications.unread.count).to eq(1)
        post "/notifications/reads/"

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("read")
        expect(user.notifications.unread.count).to eq(0)
      end

      it "marks personal and org notifications as read" do
        org_admin = create(:user, :org_admin)
        org = org_admin.organizations.first

        create_follow_notifications(org, following_user)
        create_follow_notifications(org_admin, following_user)

        expect(org_admin.notifications.unread.count).to eq(1)
        expect(org.notifications.unread.count).to eq(1)
        sign_in org_admin
        post "/notifications/reads/", params: { org_id: org.id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("read")
        expect(org_admin.notifications.unread.count).to eq(0)
        expect(org.notifications.unread.count).to eq(0)
      end
    end

    it "returns an empty response without a current_user" do
      post "/notifications/reads/"

      expect(response).to have_http_status(:no_content)
      expect(response.body).to eq("")
    end
  end
end
