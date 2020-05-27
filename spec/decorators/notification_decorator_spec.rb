require "rails_helper"

RSpec.describe NotificationDecorator, type: :decorator do
  let(:notification) { build(:notification) }

  context "with serialization" do
    let_it_be_readonly(:notification) { create(:notification).decorate }

    xit "serializes both the decorated object IDs and decorated methods" do
      expected_result = { "id" => notification.id, "milestone_type" => notification.milestone_type }
      expect(notification.as_json(only: [:id], methods: [:milestone_type])).to eq(expected_result)
    end

    xit "serializes collections of decorated objects" do
      decorated_collection = Notification.decorate
      expected_result = [{ "id" => notification.id, "milestone_type" => notification.milestone_type }]
      expect(decorated_collection.as_json(only: [:id], methods: [:milestone_type])).to eq(expected_result)
    end
  end

  describe "#mocked_object" do
    let(:comment) { create(:comment, commentable: create(:article, organization: create(:organization))) }

    xit "returns empty struct if the notification is new" do
      result = notification.decorate.mocked_object("user")

      expect(result.name).to be_empty
      expect(result.id).to be_nil
    end

    xit "returns empty struct class and its name if the notification is new" do
      result = notification.decorate.mocked_object("user")

      expect(result.class).to be_a(Struct)
      expect(result.class.name).to be_empty
    end

    xit "returns class name and id for the reactable in a struct" do
      notification = Notification.send_new_comment_notifications_without_delay(comment)

      result = notification.decorate.mocked_object("user")
      expect(result.name).to eq("User")
      expect(result.id).to eq(comment.user.id)
    end

    xit "returns struct class and its name" do
      notification = Notification.send_new_comment_notifications_without_delay(comment)
      result = notification.decorate.mocked_object("user")

      expect(result.class).to be_a(Struct)
      expect(result.class.name).to eq("User")
    end
  end

  describe "#milestone_type" do
    xit "returns empty string if there is no action" do
      expect(notification.decorate.milestone_type).to be_empty
    end

    xit "returns the type of the milestone action" do
      notification = build(:notification, action: "Milestone::Reaction::64")
      expect(notification.decorate.milestone_type).to eq("Reaction")
    end
  end

  describe "#milestone_count" do
    xit "returns empty string if there is no action" do
      expect(notification.decorate.milestone_count).to be_empty
    end

    xit "returns the count of the milestone action" do
      notification = build(:notification, action: "Milestone::Reaction::64")
      expect(notification.decorate.milestone_count).to eq("64")
    end
  end
end
