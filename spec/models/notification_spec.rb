require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:user)            { create(:user) }
  let(:user2)           { create(:user) }
  let(:user3)           { create(:user) }
  let(:article)         { create(:article, user_id: user.id) }
  let(:follow_instance) { user.follow(user2) }

  describe "#send_new_follower_notification" do
    before { Notification.send_new_follower_notification(follow_instance) }

    it "creates a notification belonging to the person being followed" do
      expect(Notification.first.user_id).to eq user2.id
    end

    it "creates a notification from the follow instance" do
      notifiable_data = { notifiable_id: Notification.first.notifiable_id, notifiable_type: Notification.first.notifiable_type }
      follow_data = { notifiable_id: follow_instance.id, notifiable_type: follow_instance.class.name }
      expect(notifiable_data).to eq follow_data
    end
  end

  # describe "#send_to_followers" do
  #   before do
  #     user2.follow user
  #     Notification.send_to_followers(article, user.followers, "Published")
  #   end
  # end
end
