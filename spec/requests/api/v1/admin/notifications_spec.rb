require "rails_helper"

RSpec.describe "Api::V1::Admin::Notifications" do
  let(:headers) { admin_api_headers }
  let(:recipient) { create(:user) }
  let(:other_recipient) { create(:user) }
  let(:events) { [] }

  def events_named(event_name)
    events.filter_map { |name, kwargs| kwargs if name == event_name }
  end

  def push(user_ids: [recipient.id], **content)
    post "/api/admin/notifications", params: { user_ids: user_ids, title: "Your MLH application", **content },
                                     headers: headers, as: :json
  end

  before do
    Audit::Subscribe.listen :admin_api
    allow(Trackable::BatchEvent).to receive(:enqueue) { |name, **kwargs| events << [name, kwargs] }
    allow(FeatureFlag).to receive(:enabled?).and_call_original
    allow(FeatureFlag).to receive(:enabled?).with(:notification_sync_events).and_return(true)
  end

  after { Audit::Subscribe.forget :admin_api }

  describe "POST /api/admin/notifications" do
    it "creates a notification per user and returns each DEV id" do
      actor = create(:user)

      expect do
        push(user_ids: [recipient.id, other_recipient.id, 999_999_999], body: "You're in!", url: "https://mlh.io/x",
             actor_id: actor.id)
      end.to change(Notification, :count).by(2).and change(AdminNotification, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      notifications = Notification.where(notifiable_type: "AdminNotification").index_by(&:user_id)
      expect(body["admin_notification_id"]).to eq(AdminNotification.last.id)
      expect(body["results"]).to eq([
                                      { "user_id" => recipient.id, "id" => notifications[recipient.id].id,
                                        "status" => "created" },
                                      { "user_id" => other_recipient.id, "id" => notifications[other_recipient.id].id,
                                        "status" => "created" },
                                      { "user_id" => 999_999_999, "status" => "not_found" },
                                    ])
      expect(notifications[recipient.id]).to have_attributes(read: false, action: nil)
      expect(notifications[recipient.id].json_data).to include(
        "admin_notification" => { "title" => "Your MLH application", "body" => "You're in!",
                                  "url" => "https://mlh.io/x" },
        "user" => hash_including("id" => actor.id),
      )
    end

    it "reports the push as one sync event and audits it" do
      push(user_ids: [recipient.id, other_recipient.id, 999_999_999], url: "https://mlh.io/x")

      sent = events_named("notifications_sent")
      expect(sent.size).to eq(1)
      expect(sent.first[:recipient_ids].zip(sent.first[:recipient_properties]["notification_ids"]))
        .to match_array(Notification.where(notifiable_type: "AdminNotification").pluck(:user_id, :id))
      expect(sent.first[:recipient_ids]).to contain_exactly(recipient.id, other_recipient.id)
      expect(sent.first[:properties]).to include("kind" => "admin", "notifiable_type" => "AdminNotification",
                                                 "text" => "Your MLH application", "url" => "https://mlh.io/x")
      expect(sent.first[:properties]).not_to include("title")
      expect(AuditLog.last).to have_attributes(slug: "create_notifications")
      expect(AuditLog.last.data).to include("recipient_count" => 2, "not_found_count" => 1)
    end

    it "deduplicates user ids" do
      push(user_ids: [recipient.id, recipient.id])

      expect(response.parsed_body["results"].size).to eq(1)
    end

    it "rejects more than MAX_RECIPIENTS users" do
      stub_const("Notifications::AdminNotifications::MAX_RECIPIENTS", 1)

      push(user_ids: [recipient.id, other_recipient.id])

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("invalid_user_ids")
    end

    it "rejects a missing user_ids array" do
      post "/api/admin/notifications", params: { title: "Hi" }, headers: headers, as: :json

      expect(response.parsed_body["error_code"]).to eq("invalid_user_ids")
    end

    it "rejects a missing title" do
      push(title: " ")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to include("error_code" => "invalid_notification_content")
      expect(response.parsed_body["error"]).to include("title")
    end

    it "rejects a script url" do
      push(url: "javascript:alert(1)")

      expect(response.parsed_body["error_code"]).to eq("invalid_notification_content")
    end

    it "accepts a same-site path but not a protocol-relative url" do
      push(url: "/settings")
      expect(response).to have_http_status(:created)

      push(url: "//evil.example")
      expect(response.parsed_body["error_code"]).to eq("invalid_notification_content")
    end

    it "rejects an unknown actor" do
      push(actor_id: 999_999_999)

      expect(response.parsed_body["error_code"]).to eq("actor_not_found")
    end

    it "fails when no user exists, without creating an anchor" do
      expect { push(user_ids: [999_999_999]) }.not_to change(AdminNotification, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("no_recipients_found")
    end

    it "requires an api key" do
      post "/api/admin/notifications", params: { user_ids: [recipient.id], title: "Hi" },
                                       headers: { "Accept" => "application/vnd.forem.api-v1+json" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with an admin notification" do
    let(:notification) do
      push(body: "Old body", url: "/old")
      Notification.find(response.parsed_body["results"].first["id"])
    end

    before { events.clear }

    describe "PUT /api/admin/notifications/:id" do
      it "updates that recipient's content in place and syncs it for them only" do
        notification.update_columns(read: true)

        put "/api/admin/notifications/#{notification.id}", params: { title: "New title", body: "" },
                                                           headers: headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include("id" => notification.id, "title" => "New title", "body" => nil,
                                                "url" => "/old", "read" => true)
        expect(notification.reload.json_data["admin_notification"]).to eq("title" => "New title", "url" => "/old")
        expect(events_named("notifications_updated").first).to include(
          recipient_ids: [recipient.id],
          recipient_properties: { "notification_ids" => [notification.id] },
          properties: hash_including("text" => "New title", "notifiable_type" => "AdminNotification"),
        )
        expect(AuditLog.last.data).to include("changed" => %w[title body])
      end

      it "refuses notifications DEV generated itself" do
        comment_notification = create(:notification, user: recipient, organization: nil,
                                                     notifiable: create(:comment))

        put "/api/admin/notifications/#{comment_notification.id}", params: { title: "x" }, headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error_code"]).to eq("notification_not_editable")
      end

      it "requires some content" do
        put "/api/admin/notifications/#{notification.id}", params: {}, headers: headers, as: :json

        expect(response.parsed_body["error_code"]).to eq("invalid_notification_content")
      end

      it "404s for an unknown id" do
        put "/api/admin/notifications/0", params: { title: "x" }, headers: headers, as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["error_code"]).to eq("notification_not_found")
      end
    end

    describe "DELETE /api/admin/notifications/:id" do
      it "deletes it and syncs the removal for that recipient" do
        delete "/api/admin/notifications/#{notification.id}", headers: headers

        expect(response).to have_http_status(:no_content)
        expect(Notification.exists?(notification.id)).to be(false)
        expect(events_named("notifications_removed").first).to include(
          recipient_ids: [recipient.id],
          recipient_properties: { "notification_ids" => [notification.id] },
          properties: hash_including("notifiable_type" => "AdminNotification",
                                     "notifiable_ids" => [notification.notifiable_id], "reason" => "admin_deleted"),
        )
        expect(AuditLog.last).to have_attributes(slug: "delete_notification")
      end
    end
  end

  it "deletes any user's notification, not only admin ones" do
    comment_notification = create(:notification, user: recipient, organization: nil, notifiable: create(:comment))

    delete "/api/admin/notifications/#{comment_notification.id}", headers: headers

    expect(response).to have_http_status(:no_content)
    expect(events_named("notifications_removed").first[:properties]).to include("notifiable_type" => "Comment")
  end

  describe "POST /api/admin/users/:user_id/notifications/read" do
    let(:base_time) { Time.zone.parse("2026-11-20T12:00:00.123456Z") }

    def notify(at)
      create(:notification, user: recipient, organization: nil, notifiable: create(:article)).tap do |n|
        n.update_columns(notified_at: at)
      end
    end

    def mark_read(**params)
      post "/api/admin/users/#{recipient.id}/notifications/read", params: params, headers: headers, as: :json
    end

    it "marks rows up to the given id, but not an older row re-notified after it" do
      re_notified = notify(base_time - 1.hour)
      older = notify(base_time - 1.minute)
      bound = notify(base_time)
      newer = notify(base_time + 1.minute)
      re_notified.update_columns(notified_at: base_time + 30.seconds)

      mark_read(up_to_id: bound.id)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("user_id" => recipient.id, "marked_read" => 2)
      expect([older, bound].map { |n| n.reload.read }).to all(be(true))
      expect([re_notified, newer].map { |n| n.reload.read }).to all(be(false))
    end

    it "marks rows notified through a time, inclusive to the millisecond" do
      at_cutoff = notify(base_time)
      after_cutoff = notify(base_time + 0.002)

      mark_read(read_through: "2026-11-20T12:00:00.123Z")

      expect(at_cutoff.reload).to have_attributes(read: true, read_at: be_present)
      expect(after_cutoff.reload.read).to be(false)
    end

    it "does not echo a notifications_read event back to the caller" do
      notify(base_time)

      mark_read(read_through: Time.current.iso8601)

      expect(events_named("notifications_read")).to be_empty
      expect(AuditLog.last.data).to include("marked_read" => 1, "target_user_id" => recipient.id)
    end

    it "only touches that user's rows" do
      other = create(:notification, user: other_recipient, organization: nil, notifiable: create(:article))

      mark_read(read_through: Time.current.iso8601)

      expect(other.reload.read).to be(false)
    end

    it "requires exactly one cutoff" do
      mark_read
      expect(response.parsed_body["error_code"]).to eq("invalid_read_cutoff")

      mark_read(up_to_id: 1, read_through: Time.current.iso8601)
      expect(response.parsed_body["error_code"]).to eq("invalid_read_cutoff")

      mark_read(read_through: "yesterday")
      expect(response.parsed_body["error_code"]).to eq("invalid_read_cutoff")
    end

    it "404s when up_to_id is not one of the user's notifications" do
      other = create(:notification, user: other_recipient, organization: nil, notifiable: create(:article))

      mark_read(up_to_id: other.id)

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error_code"]).to eq("notification_not_found")
    end
  end
end
