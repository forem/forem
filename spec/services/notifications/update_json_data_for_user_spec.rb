require "rails_helper"

RSpec.describe Notifications::UpdateJsonDataForUser, type: :service do
  let(:author)  { create(:user, username: "old_username") }
  let(:reader)  { create(:user) }
  let(:commenter) { create(:user) }

  describe "#call" do
    context "when the user authored an article with notifications" do
      let(:article) { create(:article, user: author) }

      it "updates article notification json_data with the new user path" do
        notification = create(:notification, notifiable: article, user: reader, action: "Published",
                                             json_data: { user: Notifications.user_data(author), article: Notifications.article_data(article) })

        old_path = notification.json_data["user"]["path"]
        expect(old_path).to eq("/old_username")

        author.update!(username: "new_username")
        described_class.call(author)

        notification.reload
        expect(notification.json_data["user"]["path"]).to eq("/new_username")
        expect(notification.json_data["user"]["username"]).to eq("new_username")
        expect(notification.json_data["article"]["path"]).to include("new_username")
      end

      it "updates organization data when article belongs to an org" do
        org = create(:organization)
        article = create(:article, user: author, organization: org)
        notification = create(:notification, notifiable: article, user: reader, action: "Published",
                                             json_data: { user: Notifications.user_data(author),
                                                          article: Notifications.article_data(article),
                                                          organization: Notifications.organization_data(org) })

        author.update!(username: "new_username")
        described_class.call(author)

        notification.reload
        expect(notification.json_data["user"]["path"]).to eq("/new_username")
        expect(notification.json_data["article"]["path"]).to include("new_username")
        expect(notification.json_data["organization"]["id"]).to eq(org.id)
      end
    end

    context "when the user authored a comment with notifications" do
      let(:article) { create(:article, user: reader) }
      let(:comment) { create(:comment, commentable: article, user: commenter) }

      it "updates comment notification json_data with the new comment path" do
        notification = create(:notification,
                              notifiable: comment,
                              user: reader,
                              json_data: {
                                user: Notifications.user_data(commenter),
                                comment: Notifications.comment_data(comment)
                              })

        old_comment_path = notification.json_data["comment"]["path"]
        expect(old_comment_path).to include(commenter.username)

        commenter.update!(username: "renamed_commenter")
        described_class.call(commenter)

        notification.reload
        expect(notification.json_data["comment"]["path"]).to include("renamed_commenter")
        expect(notification.json_data["user"]["username"]).to eq("renamed_commenter")
      end
    end

    context "when the user appears as the actor in non-Article/Comment notifications" do
      let(:article) { create(:article, user: reader) }
      let(:comment) { create(:comment, commentable: article, user: commenter) }
      let(:mention) { create(:mention, user: reader, mentionable: comment) }

      it "updates mention notification json_data when user is the mentionable author" do
        Notifications::NewMention::Send.call(mention)
        notification = Notification.find_by(notifiable: mention)

        expect(notification.json_data["user"]["username"]).to eq(commenter.username)

        commenter.update!(username: "renamed_commenter")
        described_class.call(commenter)

        notification.reload
        expect(notification.json_data["user"]["username"]).to eq("renamed_commenter")
        expect(notification.json_data["user"]["path"]).to eq("/renamed_commenter")
      end
    end

    context "when the user has milestone notifications" do
      let(:article) { create(:article, user: author) }

      it "updates article paths in milestone notifications" do
        notification = create(:notification, notifiable: article, user: author,
                                             action: "Milestone::Reaction::64",
                                             json_data: { article: Notifications.article_data(article) })

        author.update!(username: "new_username")
        described_class.call(author)

        notification.reload
        expect(notification.json_data["article"]["path"]).to include("new_username")
      end
    end

    context "when comments are left on the user's article by someone else" do
      let(:article) { create(:article, user: author) }
      let(:comment) { create(:comment, commentable: article, user: commenter) }

      it "updates the commentable path in comment notifications" do
        notification = create(:notification,
                              notifiable: comment,
                              user: author,
                              json_data: {
                                user: Notifications.user_data(commenter),
                                comment: Notifications.comment_data(comment)
                              })

        # The commentable path in the notification should contain the author's username
        expect(notification.json_data["comment"]["commentable"]["path"]).to include("old_username")

        author.update!(username: "new_username")
        described_class.call(author)

        notification.reload
        # The commentable path should now reflect the author's new username
        expect(notification.json_data["comment"]["commentable"]["path"]).to include("new_username")
        # The commenter's data should remain unchanged (they didn't change username)
        expect(notification.json_data["user"]["username"]).to eq(commenter.username)
      end
    end

    context "when notifications have no json_data" do
      let(:article) { create(:article, user: author) }

      it "does not raise errors for notifications without json_data" do
        notification = create(:notification, notifiable: article, user: reader, action: "Published")

        expect { described_class.call(author) }.not_to raise_error
      end
    end
  end
end
