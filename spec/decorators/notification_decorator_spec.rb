require "rails_helper"

RSpec.describe NotificationDecorator, type: :decorator do
  describe "#mocked_object" do
    it "returns empty struct if the notification is new" do
      notification = build(:notification)
      result = notification.decorate_.mocked_object("user")

      expect(result.name).to be_empty
      expect(result.id).to be_nil
    end

    it "returns class name and id for the reactable in a struct" do
      comment = create(:comment, commentable: create(:article, organization: create(:organization)))
      notification = Notification.send_new_comment_notifications_without_delay(comment)

      result = notification.decorate_.mocked_object("user")
      expect(result.name).to eq("User")
      expect(result.id).to eq(comment.user.id)
    end
  end

  describe "#milestone_type" do
    it "returns empty string if there is no action" do
      notification = build(:notification)
      expect(notification.decorate_.milestone_type).to be_empty
    end

    it "returns the type of the milestone action" do
      notification = build(:notification, action: "Milestone::Reaction::64")
      expect(notification.decorate_.milestone_type).to eq("Reaction")
    end
  end

  describe "#milestone_count" do
    it "returns empty string if there is no action" do
      notification = build(:notification)
      expect(notification.decorate_.milestone_count).to be_empty
    end

    it "returns the count of the milestone action" do
      notification = build(:notification, action: "Milestone::Reaction::64")
      expect(notification.decorate_.milestone_count).to eq("64")
    end
  end
end
