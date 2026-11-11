require "rails_helper"

RSpec.describe "NotificationCounts" do
  let(:user) { create(:user) }
  let(:following_user) { create(:user) }

  describe "GET /notifications/counts" do
    it "returns count if signed in without hydrating the full users row" do
      sign_in user
      follow_instance = following_user.follow(user)
      Notification.send_new_follower_notification_without_delay(follow_instance)
      get "/notifications/counts"

      full_user_queries = []
      callback = lambda do |*, payload|
        full_user_queries << payload[:sql] if payload[:sql].include?('SELECT "users".*')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get "/notifications/counts"
      end

      expect(response.body).to eq("1")
      expect(full_user_queries).to be_empty
    end

    it "rejects a retained session after the user's password changes" do
      sign_in user
      follow_instance = following_user.follow(user)
      Notification.send_new_follower_notification_without_delay(follow_instance)
      get "/notifications/counts"
      expect(response.body).to eq("1")

      # Simulate password change in another session, which rotates encrypted_password / authenticatable_salt in DB
      User.where(id: user.id).update_all(
        encrypted_password: "$2a$10$newpasswordsaltandhashvalue1234567890123456789012",
      )

      get "/notifications/counts"
      expect(response.body).to eq("0")
    end

    it "restores the user from remember_user_token when no session user key is present" do
      user.remember_me!
      cookie_val = User.serialize_into_cookie(user)
      signed_cookie = Rails.application.message_verifier("signed cookie").generate(cookie_val)
      follow_instance = following_user.follow(user)
      Notification.send_new_follower_notification_without_delay(follow_instance)

      get "/notifications/counts", headers: { "Cookie" => "remember_user_token=#{CGI.escape(signed_cookie)}" }
      expect(response.body).to eq("1")
      expect(request.session_options[:skip]).not_to be(true)
    end

    it "loads the session from RedisStore when authenticating via session cookie and skips post-request commit" do
      sign_in user
      follow_instance = following_user.follow(user)
      Notification.send_new_follower_notification_without_delay(follow_instance)
      # Establish the session cookie in RedisStore, then clear the test on_request hook
      # and remove remember_user_token so the next request authenticates strictly from the stored Redis session.
      get "/notifications/counts"
      Warden::Manager._on_request.clear
      cookies.delete("remember_user_token")

      full_user_queries = []
      callback = lambda do |*, payload|
        full_user_queries << payload[:sql] if payload[:sql].include?('SELECT "users".*') && !payload[:cached]
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get "/notifications/counts"
      end

      expect(response.body).to eq("1")
      expect(full_user_queries).to be_empty
      expect(request.session_options[:skip]).to be(true)
    end

    it "returns the unread count when the Redis session is valid but remember_user_token is stale or rotated" do
      sign_in user
      follow_instance = following_user.follow(user)
      Notification.send_new_follower_notification_without_delay(follow_instance)
      get "/notifications/counts"
      Warden::Manager._on_request.clear

      # Simulate remember_created_at / remember_token rotation on another device while Redis session stays active
      User.where(id: user.id).update_all(
        remember_token: "rotated_token_on_other_device",
        remember_created_at: 1.minute.from_now,
      )

      user_queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql].to_s
        user_queries << sql if (sql.include?('SELECT "users".*') || sql.include?('UPDATE "users"')) && !payload[:cached]
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get "/notifications/counts"
      end

      expect(response.body).to eq("1")
      expect(user_queries).to be_empty
      expect(request.session_options[:skip]).to be(true)
    end

    it "does not fall through to Devise Rememberable sign-in or UPDATE users when Redis session is present" do
      sign_in user
      follow_instance = following_user.follow(user)
      Notification.send_new_follower_notification_without_delay(follow_instance)
      get "/notifications/counts"
      Warden::Manager._on_request.clear

      user_queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql].to_s
        user_queries << sql if (sql.include?('SELECT "users".*') || sql.include?('UPDATE "users"')) && !payload[:cached]
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get "/notifications/counts"
      end

      expect(response.body).to eq("1")
      expect(user_queries).to be_empty
      expect(request.session_options[:skip]).to be(true)
    end

    context "when mode=detailed parameter is passed" do
      it "returns count and extended metadata in JSON" do
        sign_in user

        # Read notification (older)
        old_time = 2.days.ago
        create(:notification, user: user, action: "Reaction", read: true, read_at: old_time, notified_at: 3.days.ago)

        # Unread notification (newer)
        new_notification = create(:notification, user: user, action: "New Follower", notified_at: 1.day.ago)

        get "/notifications/counts", params: { mode: "detailed" }
        json_response = response.parsed_body

        expect(json_response["count"]).to eq(1)
        expect(json_response["last_notification_id"]).to eq(new_notification.id)
        expect(json_response["read_at"]).to be_nil # because newest is unread
        expect(json_response["notified_at"]).to eq(new_notification.notified_at.as_json)
        expect(json_response["action"]).to eq("New Follower")
      end

      it "returns count 0 and nil metadata if no user" do
        get "/notifications/counts", params: { mode: "detailed" }
        json_response = response.parsed_body

        expect(json_response["count"]).to eq(0)
        expect(json_response["last_notification_id"]).to be_nil
        expect(json_response["read_at"]).to be_nil
        expect(json_response["notified_at"]).to be_nil
      end
    end

    it "returns 0 if no user is present (plain default mode)" do
      get "/notifications/counts"
      expect(response.body).to eq("0")
    end

    context "when sign in is passed via token" do
      it "returns count for the token user (plain mode)" do
        payload = {
          user_id: user.id,
          exp: 5.minutes.from_now.to_i
        }
        token = JWT.encode(payload, Rails.application.secret_key_base)

        follow_instance = following_user.follow(user)
        Notification.send_new_follower_notification_without_delay(follow_instance)

        get "/notifications/counts", headers: { "Authorization" => "Bearer #{token}" }
        expect(response.body).to eq("1")
      end

      it "returns detailed metadata for the token user (detailed mode)" do
        payload = {
          user_id: user.id,
          exp: 5.minutes.from_now.to_i
        }
        token = JWT.encode(payload, Rails.application.secret_key_base)

        new_notification = create(:notification, user: user, action: "New Follower", notified_at: 1.day.ago)

        get "/notifications/counts", params: { mode: "detailed" }, headers: { "Authorization" => "Bearer #{token}" }
        json_response = response.parsed_body

        expect(json_response["count"]).to eq(1)
        expect(json_response["last_notification_id"]).to eq(new_notification.id)
        expect(json_response["action"]).to eq("New Follower")
      end
    end
  end
end
