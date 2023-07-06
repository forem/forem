require "rails_helper"

RSpec.describe "NotificationSubscriptions" do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:article) { create(:article, :with_notification_subscription, user: user) }
  let(:other_article) { create(:article, :with_notification_subscription, user: other_user) }
  let(:headers) { { Accept: "application/json" } }
  let(:comment) { create(:comment, commentable: article, user: user) }
  let(:parent_comment_by_og)                    { create(:comment, commentable: article, user: user) }
  let(:child_of_parent_by_other) do
    create(:comment, commentable: article, user: other_user, ancestry: parent_comment_by_og.id.to_s)
  end
  let(:child_of_child_by_og) do
    create(:comment, commentable: article, user: user,
                     ancestry: "#{parent_comment_by_og.id}/#{child_of_parent_by_other.id}")
  end
  let(:child_of_child_of_child_by_other) do
    create(:comment, commentable: article, user: other_user,
                     ancestry: "#{parent_comment_by_og.id}/#{child_of_parent_by_other.id}/#{child_of_child_by_og.id}")
  end
  let(:child_of_child_of_child_by_og) do
    path = "#{parent_comment_by_og.id}/#{child_of_parent_by_other.id}"
    ancestry = "#{path}/#{child_of_child_by_og.id}/#{child_of_child_by_other.id}"

    create(:comment, commentable: article, user: user, ancestry: ancestry)
  end
  let(:child_of_child_by_other) do
    create(:comment, commentable: article, user: other_user,
                     ancestry: "#{parent_comment_by_og.id}/#{child_of_parent_by_other.id}")
  end
  let(:child2_of_child_of_child_by_og) do
    ancestry = "#{parent_comment_by_og.id}/#{child_of_parent_by_other.id}/#{child_of_child_by_other.id}"
    create(:comment, commentable: article, user: user, ancestry: ancestry)
  end
  let(:parent_comment_by_other) { create(:comment, commentable: article, user: other_user) }

  describe "#show or GET /notification_subscriptions/:notifiable_type/:notifiable_id" do
    context "when signed in" do
      before { sign_in user }

      it "returns a JSON response" do
        get "/notification_subscriptions/Article/#{article.id}",
            headers: headers
        expect(response.media_type).to eq "application/json"
      end

      it "returns the correct subscription boolean as JSON" do
        get "/notification_subscriptions/Article/#{article.id}",
            headers: headers
        expect(response.parsed_body["config"]).to eq "all_comments"
      end

      it "returns the correct subscription boolean as JSON if unsubscribed" do
        article.notification_subscriptions.first.delete
        get "/notification_subscriptions/Article/#{article.id}",
            headers: headers
        expect(response.parsed_body["config"]).to eq "not_subscribed"
      end
    end

    it "returns a JSON response 'null' if there is no logged in user" do
      get "/notification_subscriptions/Article/#{article.id}", headers: headers
      expect(response.body).to eq "null"
      expect(response.media_type).to eq "application/json"
    end
  end

  describe "#upsert or POST /notification_subscriptions/:notifiable_type/:notifiable_id" do
    it "returns 404 if there is no logged in user" do
      expect do
        post "/notification_subscriptions/Article/#{article.id}",
             headers: headers,
             params: { config: "all_comments" }
      end.to raise_error ActiveRecord::RecordNotFound
    end

    context "when sent as a JSON request with the correct params" do
      before { sign_in user }

      it "completes a proper subscription" do
        post "/notification_subscriptions/Article/#{other_article.id}",
             headers: headers,
             params: { currently_subscribed: "false" }
        subscription = NotificationSubscription.last
        expect(subscription.user_id).to eq user.id
        expect(subscription.notifiable_id).to eq other_article.id
        expect(subscription.notifiable_type).to eq "Article"
      end

      it "removes a previous subscription" do
        subscription = article.notification_subscriptions.first
        post "/notification_subscriptions/Article/#{article.id}",
             headers: headers,
             params: { config: "not_subscribed" }

        expect { subscription.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "updates the article.receive_notifications column correctly if the current_user is the author" do
        post "/notification_subscriptions/Article/#{article.id}",
             headers: headers,
             params: { config: "not_subscribed" }
        expect(article.reload.receive_notifications).to be false
      end

      it "updates the comment.receive_notifications column correctly if the current_user is the commenter" do
        post "/notification_subscriptions/Comment/#{comment.id}",
             headers: headers,
             params: { config: "not_subscribed" }
        expect(comment.reload.receive_notifications).to be false
      end
    end

    context "when an article has two parent comments by two different people" do
      before do
        sign_in user
        parent_comment_by_og
        parent_comment_by_other
      end

      it "mutes the parent comment" do
        params = { config: "not_subscribed" }
        post "/notification_subscriptions/Comment/#{parent_comment_by_og.id}", headers: headers, params: params

        expect(parent_comment_by_og.reload.receive_notifications).to be(false)
      end

      it "does not mute the someone else's parent comment" do
        params = { config: "all_comments" }
        post "/notification_subscriptions/Comment/#{parent_comment_by_og.id}", headers: headers, params: params

        expect(parent_comment_by_other.reload.receive_notifications).to be(true)
      end

      it "unmutes the parent comment if already muted" do
        parent_comment_by_og.update(receive_notifications: false)

        params = { config: "all_comments" }
        post "/notification_subscriptions/Comment/#{parent_comment_by_og.id}", headers: headers, params: params

        expect(parent_comment_by_og.reload.receive_notifications).to be(true)
      end
    end

    context "when an article has a single comment thread with multiple commenters" do
      before do
        child_of_child_of_child_by_og
        child_of_child_of_child_by_other
        child2_of_child_of_child_by_og
        parent_comment_by_other
        sign_in user

        params = { config: "not_subscribed" }
        post "/notification_subscriptions/Comment/#{parent_comment_by_og.id}", headers: headers, params: params
      end

      it "mutes all of the original commenter's comments in a single thread" do
        user_ids_of_muted_comments = Comment.where(receive_notifications: false).pluck(:user_id)
        expect(user_ids_of_muted_comments.uniq).to eq [user.id]
      end

      it "does not mute someone else's comment of a different thread" do
        expect(parent_comment_by_other.receive_notifications).to be true
      end

      it "does not mute the other commenter's comments in the same thread" do
        results = parent_comment_by_og.subtree.where(user: other_user).pluck(:receive_notifications)
        expect(results.uniq).to eq [true]
      end
    end
  end

  describe "POST /comments/subscribe" do
    let(:subscribe_service_result) { { updated: true } }
    let(:request_params) { { comment_id: 1, article_id: 2 } }

    before do
      sign_in user

      allow(NotificationSubscriptions::Subscribe).to receive(:call)
        .and_return(subscribe_service_result)

      post "/comments/subscribe", params: request_params
    end

    it "calls the Subscribe service object with the correct parameters" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(subscribe_service_result.to_json)
      expect(NotificationSubscriptions::Subscribe).to \
        have_received(:call)
        .with(user, comment_id: "1", article_id: "2", config: "all_comments")
    end

    context "when setting subscription config in the request parameters" do
      let(:request_params) do
        { article_id: 3, subscription_config: "top_level_comments" }
      end

      it "calls the Subscribe service object with the correct parameters" do
        expect(NotificationSubscriptions::Subscribe).to \
          have_received(:call)
          .with(user, a_hash_including(article_id: "3", config: "top_level_comments"))
      end
    end
  end

  describe "POST /subscription/unsubscribe" do
    before do
      sign_in user

      allow(NotificationSubscriptions::Unsubscribe).to receive(:call)
        .and_return({ destroyed: true })

      post "/subscription/unsubscribe", params: { subscription_id: 1 }
    end

    it "calls the Unsubscribe service object with the correct parameters" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("{\"destroyed\":true}")
      expect(NotificationSubscriptions::Unsubscribe).to \
        have_received(:call).with(user, "1")
    end
  end
end
