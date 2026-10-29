require "rails_helper"

# rubocop:disable RSpec/MultipleExpectations
RSpec.describe NotificationDecorator, type: :decorator do
  def build(name, *traits, **attrs)
    return Notification.new({ notifiable_type: "Article" }.merge(attrs)) if name == :notification

    super
  end

  let(:notification) { build(:notification) }

  context "with serialization" do
    let(:notification) { create(:notification, organization: nil).decorate }

    it "serializes both decorated objects and collections of decorated objects" do
      expected_result = { "id" => notification.id, "milestone_type" => notification.milestone_type }
      expect(notification.as_json(only: [:id], methods: [:milestone_type])).to eq(expected_result)

      decorated_collection = Notification.decorate
      expect(decorated_collection.as_json(only: [:id], methods: [:milestone_type])).to eq([expected_result])
    end
  end

  describe "#mocked_object" do
    let(:comment) { create(:comment, commentable: create(:article, organization: create(:organization))) }

    it "returns an empty struct and class name if the notification is new" do
      result = notification.decorate.mocked_object("user")

      expect(result.name).to be_empty
      expect(result.id).to be_nil
      expect(result.class).to be_a(Struct)
      expect(result.class.name).to be_empty
    end

    it "returns class name, id, and struct class for the reactable" do
      notification = Notification.send_new_comment_notifications_without_delay(comment)
      result = notification.decorate.mocked_object("user")

      expect(result.name).to eq("User")
      expect(result.id).to eq(comment.user.id)
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

    it "is a milestone type" do
      notification = build(:notification, action: "Milestone::Reaction::64")
      expect(notification.notifiable_type).to eq("Article")
      expect(notification.decorate).to be_milestone
    end

    it "is also a milestone type if has milestone type" do
      notification = build(:notification, notifiable_type: "Milestone")
      expect(notification.decorate).to be_milestone
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

    let(:notification) do
      build(:notification,
            notifiable_type: "Reaction",
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

    it "returns a partial path" do
      expect(decorated.to_partial_path).to eq("notifications/single_reaction")
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

    it "responds to reactable_type" do
      expect(decorated.reactable_type).to be_nil
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

    it "responds to article fields (even if blank)" do
      expect(decorated.article_id).to be_nil
      expect(decorated.article_url).to be_nil
      expect(decorated.article_title).to be_nil
      expect(decorated.article_tag_list).to eq([])
      expect(decorated.article_updated_at).to be_nil
    end

    it "responds to comment and commentable fields (even if blank)" do
      expect(decorated.comment_id).to be_blank
      expect(decorated.commentable_article_id).to be_blank
      expect(decorated.comment_ancestry).to be_blank
      expect(decorated.comment_last_ancestor).to eq({})
      expect(decorated.comment_path).to be_blank
      expect(decorated.comment_depth).to eq(-1)
      expect(decorated.comment_processed_html).to be_blank
      expect(decorated.comment_updated_at).to be_blank
      expect(decorated.commentable_class_name).to be_blank
    end
  end

  describe "reaction to a comment" do
    subject(:decorated) { notification.decorate }

    let(:notification) do
      build(:notification,
            notifiable_type: "Reaction",
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

    it "responds to reactable_type" do
      expect(decorated.reactable_type).to be_nil
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

    it "responds to article fields (even if blank)" do
      expect(decorated.article_id).to be_nil
      expect(decorated.article_url).to be_nil
      expect(decorated.article_title).to be_nil
      expect(decorated.article_tag_list).to eq([])
      expect(decorated.article_updated_at).to be_nil
    end

    it "responds to comment and commentable fields (even if blank)" do
      expect(decorated.comment_id).to be_blank
      expect(decorated.commentable_article_id).to be_blank
      expect(decorated.comment_ancestry).to be_blank
      expect(decorated.comment_last_ancestor).to eq({})
      expect(decorated.comment_path).to be_blank
      expect(decorated.comment_depth).to eq(-1)
      expect(decorated.comment_processed_html).to be_blank
      expect(decorated.comment_updated_at).to be_blank
      expect(decorated.commentable_class_name).to be_blank
    end
  end

  describe "notification relating to an article" do
    # TODO: refactor notification specs should probably have baseline shared
    # examples that apply in multiple cases?
    subject(:decorated) { notification.decorate }

    let(:article_id) { 2 }

    let(:notification) do
      build(:notification,
            notifiable_id: article_id,
            notifiable_type: "Article",
            action: "Moderation",
            json_data: {
              "user" => {
                "id" => 1,
                "name" => "A. User",
                "path" => "/a_user",
                "class" => { "name" => "User" },
                "username" => "a_user",
                "created_at" => "2022-06-03T18:43:50.465Z",
                "comments_count" => 1,
                "profile_image_90" => "/uploads/user/profile_image/1/e78aa295.png"
              },
              "article" => {
                "id" => article_id,
                "url" => "https://example.com/a_user/article-here",
                "path" => "/a_user/article-here",
                "class" => { "name" => "Article" },
                "title" => "Article Here",
                "updated_at" => "2023-06-02T06:55:53.406Z",
                "cached_tag_list_array" => []
              },
              "article_user" => {
                "id" => 3,
                "name" => "A. Differentuser",
                "path" => "/a_differentuser",
                "class" => { "name" => "User" },
                "username" => "a_differentuser",
                "created_at" => "2022-08-08T14:01:55.666Z",
                "comments_count" => 3,
                "profile_image_90" => "/uploads/user/profile_image/3/99mvlsfu5tfj9m7ku25d.png"
              }
            })
    end

    context "when a user may have a subscription" do
      let(:subscriber) { build_stubbed(:user) }
      let(:non_subscriber) { build_stubbed(:user) }
      let(:mock_subscriptions) { class_double NotificationSubscription }
      let(:mock_non_subscriptions) { class_double NotificationSubscription }

      before do
        allow(mock_subscriptions).to receive(:for_notifiable)
          .and_return([:found])
        allow(mock_non_subscriptions).to receive(:for_notifiable)
          .and_return([])
        allow(subscriber).to receive(:notification_subscriptions)
          .and_return(mock_subscriptions)
        allow(non_subscriber).to receive(:notification_subscriptions)
          .and_return(mock_non_subscriptions)
      end

      it "can find the user's article subscription" do
        expect(decorated.subscription_for(subscriber)).to \
          eq(:found)
        expect(mock_subscriptions).to have_received(:for_notifiable)
          .with(notifiable_type: "Article", notifiable_id: article_id)
      end

      it "can find article's id, path title, tag_list and updated_at" do
        expect(decorated.article_id).to eq(article_id)
        expect(decorated.article_url).to eq("https://example.com/a_user/article-here")
        expect(decorated.article_title).to eq("Article Here")
        expect(decorated.article_tag_list).to eq([])
        expect(decorated.article_updated_at).to eq("2023-06-02T06:55:53.406Z")
      end

      it "falls back to path or cleans malformed double ports in article_url" do
        double_port_article = { "url" => "http://localhost:3000:3100/a_user/article-here",
                                "path" => "/a_user/article-here" }
        double_port_notif = build(:notification, json_data: { "article" => double_port_article }).decorate
        expect(double_port_notif.article_url).to eq("/a_user/article-here")

        no_path_article = { "url" => "http://localhost:3000:3100/a_user/article-here" }
        no_path_notif = build(:notification, json_data: { "article" => no_path_article }).decorate
        expect(no_path_notif.article_url).to eq("http://localhost:3000/a_user/article-here")
      end

      it "responds to comment and commentable fields (even if blank)" do
        expect(decorated.comment_id).to be_blank
        expect(decorated.commentable_article_id).to be_blank
        expect(decorated.comment_ancestry).to be_blank
        expect(decorated.comment_last_ancestor).to eq({})
        expect(decorated.comment_path).to be_blank
        expect(decorated.comment_depth).to eq(-1)
        expect(decorated.comment_processed_html).to be_blank
        expect(decorated.comment_updated_at).to be_blank
        expect(decorated.commentable_class_name).to be_blank
      end
    end
  end

  describe "notification relating to a comment without ancestry" do
    # TODO: refactor notification specs should probably have baseline shared
    # examples that apply in multiple cases?
    subject(:decorated) { notification.decorate }

    let(:comment_id) { 2 }
    let(:article_id) { 3 }

    let(:notification) do
      build(:notification,
            notifiable_id: comment_id,
            notifiable_type: "Comment",
            action: nil,
            json_data: {
              "user" => {
                "id" => 1,
                "name" => "A. User",
                "path" => "/a_user",
                "class" => { "name" => "User" },
                "username" => "aleta_macgyver",
                "created_at" => "2022-08-08T14:01:55.666Z",
                "comments_count" => 5,
                "profile_image_90" => "/uploads/user/profile_image/3/99mvlsfu5tfj9m7ku25d.png"
              },
              "comment" => {
                "id" => comment_id,
                "path" => "/a_user/comment/2",
                "class" => { "name" => "Comment" },
                "depth" => 0,
                "ancestry" => nil,
                "ancestors" => [],
                "created_at" => "2023-06-09T13:03:21.465Z",
                "updated_at" => "2023-06-09T13:03:21.594Z",
                "commentable" => {
                  "id" => article_id,
                  "path" => "/org5997/some-article",
                  "class" => { "name" => "Article" },
                  "title" => "Some Article"
                },
                "processed_html" => "<p>Comment here</p>\n\n"
              }
            })
    end

    context "when a user may have a subscription" do
      let(:subscriber) { build_stubbed(:user) }
      let(:non_subscriber) { build_stubbed(:user) }
      let(:mock_subscriptions) { class_double NotificationSubscription }
      let(:mock_non_subscriptions) { class_double NotificationSubscription }

      before do
        allow(mock_subscriptions).to receive(:for_notifiable)
          .and_return([:found])
        allow(mock_non_subscriptions).to receive(:for_notifiable)
          .and_return([])
        allow(subscriber).to receive(:notification_subscriptions)
          .and_return(mock_subscriptions)
        allow(non_subscriber).to receive(:notification_subscriptions)
          .and_return(mock_non_subscriptions)
      end

      it "can find the user's article subscription" do
        expect(decorated.subscription_for(subscriber)).to \
          eq(:found)
        expect(mock_subscriptions).to have_received(:for_notifiable)
          .with(notifiable_type: "Comment", notifiable_id: comment_id)
          .with(notifiable_type: "Article", notifiable_id: article_id)
      end

      it "responds to article fields (even if blank)" do
        expect(decorated.article_id).to be_blank
        expect(decorated.article_url).to be_blank
        expect(decorated.article_title).to be_blank
        expect(decorated.article_tag_list).to eq([])
        expect(decorated.article_updated_at).to be_blank
      end

      it "can find comment and commentable's id, path, depth, html, etc" do
        expect(decorated.comment_id).to eq(comment_id)
        expect(decorated.commentable_article_id).to eq(article_id)
        expect(decorated.comment_ancestry).to be_blank
        expect(decorated.comment_last_ancestor).to eq({})
        expect(decorated.comment_path).to eq("/a_user/comment/2")
        expect(decorated.comment_depth).to eq(0)
        expect(decorated.comment_processed_html).to eq("<p>Comment here</p>\n\n")
        expect(decorated.comment_updated_at).to eq("2023-06-09T13:03:21.594Z")
        expect(decorated.commentable_class_name).to eq("Article")
      end
    end
  end

  describe "notification relating to a comment **with** ancestry" do
    # TODO: refactor notification specs should probably have baseline shared
    # examples that apply in multiple cases?
    subject(:decorated) { notification.decorate }

    let(:comment_id) { 2 }
    let(:ancestor_ids) { "5/6/7" }
    let(:article_id) { 3 }

    let(:notification) do
      build(:notification,
            notifiable_id: comment_id,
            notifiable_type: "Comment",
            action: nil,
            json_data: {
              "user" => {
                "id" => 1,
                "name" => "A. User",
                "path" => "/a_user",
                "class" => { "name" => "User" },
                "username" => "a_user",
                "created_at" => "2022-08-08T14:01:55.666Z",
                "comments_count" => 4,
                "profile_image_90" => "/uploads/user/profile_image/3/99mvlsfu5tfj9m7ku25d.png"
              },
              "comment" => {
                "id" => comment_id,
                "path" => "/a_user/comment/#{comment_id}",
                "class" => { "name" => "Comment" },
                "depth" => 3,
                "ancestry" => "5/6/7",
                "ancestors" =>
                        [
                          { "id" => 5,
                            "path" => "/other_user/comment/2m",
                            "user" => { "name" => "Other User", "username" => "other_user" },
                            "depth" => 0,
                            "title" => "Hello, I have commented here. (Thus, presumably having a subscription.)",
                            "ancestry" => nil },
                          { "id" => 6,
                            "path" => "/a_user/comment/2n",
                            "user" => { "name" => "A. User", "username" => "a_user" },
                            "depth" => 1,
                            "title" => "Replying to your comment.",
                            "ancestry" => "5" },
                          { "id" => 7,
                            "path" => "/other_user/comment/2o",
                            "user" => { "name" => "Other User", "username" => "other_user" },
                            "depth" => 2,
                            "title" => "Replying to the reply to the comment.",
                            "ancestry" => "5/6" },
                        ],
                "title" => "Hello I am Comment",
                "created_at" => "2023-06-09T12:56:56.572Z",
                "updated_at" => "2023-06-09T12:56:56.572Z",
                "commentable" => {
                  "id" => article_id,
                  "path" => "/org5997/some-article",
                  "class" => { "name" => "Article" },
                  "title" => "Some Article"
                },
                "processed_html" => "<p>Not a top comment.</p>\n\n"
              }
            })
    end

    context "when a user may have a subscription" do
      let(:subscriber) { build_stubbed(:user) }
      let(:non_subscriber) { build_stubbed(:user) }
      let(:mock_subscriptions) { class_double NotificationSubscription }
      let(:mock_non_subscriptions) { class_double NotificationSubscription }

      before do
        allow(mock_subscriptions).to receive(:for_notifiable)
          .and_return([:found])
        allow(mock_non_subscriptions).to receive(:for_notifiable)
          .and_return([])
        allow(subscriber).to receive(:notification_subscriptions)
          .and_return(mock_subscriptions)
        allow(non_subscriber).to receive(:notification_subscriptions)
          .and_return(mock_non_subscriptions)
      end

      it "can find the user's article subscription" do
        expect(decorated.subscription_for(subscriber)).to \
          eq(:found)
        expect(mock_subscriptions).to have_received(:for_notifiable)
          .with(notifiable_type: "Comment", notifiable_id: ancestor_ids.split("/")) # ActiveRecord will work with strings or ids, but mock needs to be specific # rubocop:disable Layout/LineLength
      end

      it "responds to article fields (even if blank)" do
        expect(decorated.article_id).to be_blank
        expect(decorated.article_url).to be_blank
        expect(decorated.article_title).to be_blank
        expect(decorated.article_tag_list).to eq([])
        expect(decorated.article_updated_at).to be_blank
      end

      it "can find comment and commentable's id, path, depth, html, etc" do
        expect(decorated.comment_id).to eq(comment_id)
        expect(decorated.commentable_article_id).to eq(article_id)
        expect(decorated.comment_ancestry).to eq(ancestor_ids)
        expect(decorated.comment_last_ancestor).to match(a_hash_including({
                                                                            "id" => 7,
                                                                            "path" => "/other_user/comment/2o",
                                                                            "title" => "Replying to the reply to the comment." # rubocop:disable Layout/LineLength
                                                                          }))
        expect(decorated.comment_path).to eq("/a_user/comment/2")
        expect(decorated.comment_depth).to eq(3)
        expect(decorated.comment_processed_html).to eq("<p>Not a top comment.</p>\n\n")
        expect(decorated.comment_updated_at).to eq("2023-06-09T12:56:56.572Z")
        expect(decorated.commentable_class_name).to eq("Article")
      end
    end
  end

  describe ".decorate_collection" do
    it "batches subscription lookups across the collection and preserves precedence" do
      user = create(:user)
      article = create(:article)
      root_comment = create(:comment, commentable: article)
      reply_comment = create(:comment, commentable: article, parent: root_comment)

      root_sub = create(:notification_subscription, user: user, notifiable: root_comment)
      article_sub = create(:notification_subscription, user: user, notifiable: article)

      reply_notif = build(:notification, notifiable_type: "Comment", json_data: {
                            "comment" => { "id" => reply_comment.id, "ancestry" => root_comment.id.to_s,
                                           "commentable" => { "id" => article.id, "class" => { "name" => "Article" } } }
                          })
      article_notif = build(:notification, notifiable_type: "Article",
                                           json_data: { "article" => { "id" => article.id } })

      decorated_list = described_class.decorate_collection([reply_notif, article_notif])

      expect(decorated_list.map { |n| n.subscription_for(user) }).to eq([root_sub, article_sub])
    end

    it "batches reaction existence lookups across the collection across categories" do
      user = create(:user, :trusted)
      article = create(:article)
      comment = create(:comment, commentable: article)

      create(:reaction, user: user, reactable: article, category: "like")
      create(:reaction, user: user, reactable: comment, category: "thumbsdown")

      article_notif = build(:notification, notifiable_type: "Article", json_data: {
                              "article" => { "id" => article.id, "class" => { "name" => "Article" } }
                            })
      comment_notif = build(:notification, notifiable_type: "Comment", json_data: {
                              "comment" => { "id" => comment.id, "class" => { "name" => "Comment" } }
                            })

      decorated_list = described_class.decorate_collection([article_notif, comment_notif])
      allow(Reaction).to receive(:cached_any_reactions_for?)
      reaction_selects = 0
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        reaction_selects += 1 if payload[:sql].include?('FROM "reactions"')
      end

      expect(decorated_list.first.any_cached_reactions_for_object?(user)).to be(true)
      expect(decorated_list.first.any_cached_reactions_for_object?(user, category: "readinglist")).to be(false)
      expect(
        decorated_list.second.any_cached_reactions_for_object?(user, "comment", category: "thumbsdown"),
      ).to be(true)
      expect(decorated_list.second.any_cached_reactions_for_object?(user, "comment", category: "like")).to be(false)
      ActiveSupport::Notifications.unsubscribe(subscriber)
      expect(Reaction).not_to have_received(:cached_any_reactions_for?)
      expect(reaction_selects).to eq(1)
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
