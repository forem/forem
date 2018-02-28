require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:user)        { create(:user) }
  let(:user2)        { create(:user) }
  let(:user3)        { create(:user) }
  let(:article)     { create(:article, user_id: user.id) }

  it "sends notifications to all followers of article user" do
    user2.follow(user)
    user3.follow(user)
    Notification.send_all_without_delay(article, "Published")
    expect(Notification.all.size).to eq(2)
  end

  it "sends sends a broadcast to everyone" do
    user2.follow(user)
    user3.follow(user)
    broadcast = Broadcast.create!(processed_html: "Hello",
                                 title: "test broadcast",
                                 type_of: "Announcement")
    Notification.send_all_without_delay(broadcast, "Announcement")
    expect(Notification.all.size).to eq(3)
  end

  it "removes all notifications" do
    user2.follow(user)
    user3.follow(user)
    Notification.send_all_without_delay(article, "Published")
    Notification.remove_all_without_delay(article, "Published")
    expect(Notification.all.size).to eq(0)
  end

end