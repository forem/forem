require "rails_helper"

RSpec.describe NotificationDecorator, type: :decorator do
  describe "#mocked_object" do
    let(:comment) { create(:comment, commentable: create(:article, organization: create(:organization))) }

    it "returns empty struct if the notification is new" do
      notification = build(:notification)
      result = notification.decorate.mocked_object("user")

      expect(result.name).to be_empty
      expect(result.id).to be_nil
    end

    it "returns empty struct class and its name if the notification is new" do
      notification = build(:notification)
      result = notification.decorate.mocked_object("user")

      expect(result.class).to be_a(Struct)
      expect(result.class.name).to be_empty
    end

    it "returns class name and id for the reactable in a struct" do
      notification = Notification.send_new_comment_notifications_without_delay(comment)

      result = notification.decorate.mocked_object("user")
      expect(result.name).to eq("User")
      expect(result.id).to eq(comment.user.id)
    end

    it "returns struct class and its name" do
      notification = Notification.send_new_comment_notifications_without_delay(comment)
      result = notification.decorate.mocked_object("user")

      expect(result.class).to be_a(Struct)
      expect(result.class.name).to eq("User")
    end
  end

  describe "#milestone_type" do
    it "returns empty string if there is no action" do
      notification = build(:notification)
      expect(notification.decorate.milestone_type).to be_empty
    end

    it "returns the type of the milestone action" do
      notification = build(:notification, action: "Milestone::Reaction::64")
      expect(notification.decorate.milestone_type).to eq("Reaction")
    end
  end

  describe "#milestone_count" do
    it "returns empty string if there is no action" do
      notification = build(:notification)
      expect(notification.decorate.milestone_count).to be_empty
    end

    it "returns the count of the milestone action" do
      notification = build(:notification, action: "Milestone::Reaction::64")
      expect(notification.decorate.milestone_count).to eq("64")
    end
  end
end
