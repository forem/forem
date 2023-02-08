require "rails_helper"

RSpec.describe NotificationDecorator, type: :decorator do
  let!(:notification) { build(:notification) }

  context "with serialization" do
    let(:notification) { create(:notification).decorate }

    it "serializes both the decorated object IDs and decorated methods" do
      expected_result = { "id" => notification.id, "milestone_type" => notification.milestone_type }
      expect(notification.as_json(only: [:id], methods: [:milestone_type])).to eq(expected_result)
    end

    it "serializes collections of decorated objects" do
      decorated_collection = Notification.decorate
      expected_result = [{ "id" => notification.id, "milestone_type" => notification.milestone_type }]
      expect(decorated_collection.as_json(only: [:id], methods: [:milestone_type])).to eq(expected_result)
    end
  end

  describe "#mocked_object" do
    let(:comment) { create(:comment, commentable: create(:article, organization: create(:organization))) }

    it "returns empty struct if the notification is new" do
      result = notification.decorate.mocked_object("user")

      expect(result.name).to be_empty
      expect(result.id).to be_nil
    end

    it "returns empty struct class and its name if the notification is new" do
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
      expect(result.class_name).to eq("User")
    end
  end

  describe "#milestone_type" do
    it "returns empty string if there is no action" do
      expect(notification.decorate.milestone_type).to be_empty
    end

    it "returns the type of the milestone action" do
      notification = build(:notification, action: "Milestone::Reaction::64")
      expect(notification.decorate.milestone_type).to eq("Reaction")
    end
  end

  describe "#milestone_count" do
    it "returns empty string if there is no action" do
      expect(notification.decorate.milestone_count).to be_empty
    end

    it "returns the count of the milestone action" do
      notification = build(:notification, action: "Milestone::Reaction::64")
      expect(notification.decorate.milestone_count).to eq("64")
    end
  end

  describe "reaction to a article" do
    subject(:decorated) { notification.decorate }

    let!(:notification) do
      article = build(:article)
      reaction = build(:reaction, reactable: article)

      build(:notification,
            notifiable: reaction,
            action: "Reaction",
            json_data: {
              reaction: {
                category: "like",
                reactable_type: "Article",
                reactable_id: 123,
                reactable: {
                  path: "path/to/article",
                  title: "This is the article's title here",
                  class: {
                    name: "Article"
                  }
                }
              }
            })
    end

    it "responds to reactable_class" do
      expect(decorated.reactable_class).to eq("Article")
    end

    it "responds to reactable_path" do
      expect(decorated.reactable_path).to eq("path/to/article")
    end

    it "responds to reactable_title (even if blank)" do
      expect(decorated.reactable_title).to eq("This is the article's title here")
    end

    it "responds to reaction_category" do
      expect(decorated.reaction_category).to eq("like")
    end

    it "is a reaction?" do
      expect(decorated).to be_reaction
    end

    it "responds to user fields (even if blank)" do
      expect(decorated.user_id).to be_nil
      expect(decorated.user_name).to be_nil
      expect(decorated.user_path).to be_nil
      expect(decorated.user_profile_image_90).to be_nil
    end
  end

  describe "reaction to a comment" do
    subject(:decorated) { notification.decorate }

    let!(:notification) do
      article = build(:article)
      comment = build(:comment, commentable: article)
      reaction = build(:reaction, reactable: comment)

      build(:notification,
            notifiable: reaction,
            action: "Reaction",
            json_data: {
              reaction: {
                category: "like",
                reactable_type: "Comment",
                reactable_id: 123,
                reactable: {
                  path: "path/to/comment",
                  title: nil,
                  class: {
                    name: "Comment"
                  }
                }
              },
              user: {
                id: 456,
                name: "Commentator",
                path: "path/to/user",
                profile_image_90: "path/to/profile/image"
              }
            })
    end

    it "responds to reactable_class" do
      expect(decorated.reactable_class).to eq("Comment")
    end

    it "responds to reactable_path" do
      expect(decorated.reactable_path).to eq("path/to/comment")
    end

    it "responds to reactable_title (even if blank)" do
      expect(decorated.reactable_title).to be_nil
    end

    it "responds to reaction_category" do
      expect(decorated.reaction_category).to eq("like")
    end

    it "is a reaction?" do
      expect(decorated).to be_reaction
    end

    it "responds to user fields (even if blank)" do
      expect(decorated.user_id).to eq(456)
      expect(decorated.user_name).to eq("Commentator")
      expect(decorated.user_path).to eq("path/to/user")
      expect(decorated.user_profile_image_90).to eq("path/to/profile/image")
    end
  end
end
