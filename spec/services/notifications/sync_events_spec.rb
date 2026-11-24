require "rails_helper"

RSpec.describe Notifications::SyncEvents, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:reader) { create(:user) }

  def notification_for(recipient, **attributes)
    json_data = { user: Notifications.user_data(user), article: Notifications.article_data(article) }
    build(:notification, user: recipient, organization: nil, notifiable: article, action: "Published",
                         notified_at: Time.zone.parse("2026-11-20T14:02:11.482Z"), json_data: json_data, **attributes)
  end

  before { allow(Trackable::BatchEvent).to receive(:enqueue) }

  context "when the notification_sync_events flag is off" do
    it "sends nothing" do
      described_class.sent(notification_for(reader), recipients: { reader.id => 1 })
      described_class.read_all(user_id: reader.id, read_at: Time.current)
      described_class.removed(notifiable_type: "Article", notifiable_ids: [article.id], reason: "content_removed")

      expect(Trackable::BatchEvent).not_to have_received(:enqueue)
    end
  end

  context "when the notification_sync_events flag is on" do
    before do
      allow(FeatureFlag).to receive(:enabled?).and_call_original
      allow(FeatureFlag).to receive(:enabled?).with(:notification_sync_events).and_return(true)
    end

    describe ".sent" do
      it "sends one notifications_sent event for every recipient of a fan-out, with each row's id" do
        described_class.sent(notification_for(reader), recipients: { reader.id => 11, user.id => 12, nil => 13 })

        expect(Trackable::BatchEvent).to have_received(:enqueue).once.with(
          "notifications_sent",
          properties: hash_including(
            "schema_version" => 1,
            "occurred_at" => "2026-11-20T14:02:11.482Z",
            "notified_at" => "2026-11-20T14:02:11.482Z",
            "notifiable_type" => "Article",
            "notifiable_id" => article.id,
            "action" => "Published",
            "kind" => "new_post",
            "read" => false,
            "text" => "#{user.name} made a new post: #{article.title}",
          ),
          anonymous_id: "dev:notifications",
          recipient_ids: [reader.id, user.id],
          recipient_properties: { "notification_ids" => [11, 12] },
        )
      end

      it "gives every dispatch its own dispatch_id" do
        2.times { described_class.sent(notification_for(reader), recipients: { reader.id => 1 }) }

        ids = []
        expect(Trackable::BatchEvent).to have_received(:enqueue).twice do |_name, properties:, **|
          ids << properties["dispatch_id"]
        end
        expect(ids.uniq.size).to eq(2)
      end

      it "skips organization-owned rows" do
        described_class.sent(notification_for(nil, organization: create(:organization)), recipients: { nil => 1 })

        expect(Trackable::BatchEvent).not_to have_received(:enqueue)
      end

      it "skips moderation notifications" do
        described_class.sent(notification_for(reader, action: "Moderation"), recipients: { reader.id => 1 })

        expect(Trackable::BatchEvent).not_to have_received(:enqueue)
      end

      it "keeps every property JSON-safe for Sidekiq strict args" do
        allow(Trackable::BatchEvent).to receive(:enqueue).and_call_original

        expect do
          described_class.sent(notification_for(reader), recipients: { reader.id => 1 })
        end.not_to raise_error
      end
    end

    describe ".updated" do
      it "sends the refreshed display fields without recipients" do
        described_class.updated(notification_for(nil))

        expect(Trackable::BatchEvent).to have_received(:enqueue).with(
          "notifications_updated",
          properties: {
            "schema_version" => 1,
            "occurred_at" => kind_of(String),
            "notifiable_type" => "Article",
            "notifiable_id" => article.id,
            "action" => "Published",
            "text" => "#{user.name} made a new post: #{article.title}",
            "url" => URL.url(article.path),
            "recipient_user_ids" => nil,
            "notification_ids" => nil
          },
          anonymous_id: "dev:notifications",
          recipient_ids: nil,
          recipient_properties: {},
        )
      end

      it "can scope the update to some recipients, naming their rows" do
        described_class.updated(notification_for(reader), recipients: { reader.id => 5 })

        expect(Trackable::BatchEvent).to have_received(:enqueue).with(
          "notifications_updated", properties: hash_including("notifiable_id" => article.id),
                                   anonymous_id: "dev:notifications", recipient_ids: [reader.id],
                                   recipient_properties: { "notification_ids" => [5] }
        )
      end
    end

    describe ".removed" do
      it "chunks notifiable ids and shares one removal_id" do
        stub_const("#{described_class}::MAX_NOTIFIABLE_IDS", 2)

        described_class.removed(notifiable_type: "Comment", notifiable_ids: [3, 1, 2, 3], all_actions: true,
                                reason: "spam")

        chunks = []
        expect(Trackable::BatchEvent).to have_received(:enqueue).twice do |name, properties:, recipient_ids:, **|
          expect(name).to eq("notifications_removed")
          expect(recipient_ids).to be_nil
          chunks << properties
        end
        expect(chunks.pluck("notifiable_ids")).to eq([[3, 1], [2]])
        expect(chunks.pluck("chunk_index")).to eq([0, 1])
        expect(chunks.pluck("chunk_count", "removal_id", "all_actions", "reason", "recipient_user_ids").uniq)
          .to eq([[2, chunks.first["removal_id"], true, "spam", nil]])
      end

      it "scopes the removal to recipients when given, with each removed row's id" do
        described_class.removed(notifiable_type: "Article", notifiable_ids: [article.id], action: "CoAuthor",
                                recipients: { reader.id => 42 }, reason: "co_author_removed")

        expect(Trackable::BatchEvent).to have_received(:enqueue).with(
          "notifications_removed", properties: hash_including("action" => "CoAuthor", "all_actions" => false),
                                   anonymous_id: "dev:notifications", recipient_ids: [reader.id],
                                   recipient_properties: { "notification_ids" => [42] }
        )
      end

      it "leaves notification_ids null when the removed row's id is unknown" do
        described_class.removed(notifiable_type: "Article", notifiable_ids: [article.id], action: "Reaction",
                                recipients: { reader.id => nil }, reason: "reaction_removed")

        expect(Trackable::BatchEvent).to have_received(:enqueue).with(
          "notifications_removed", properties: hash_including("notification_ids" => nil),
                                   anonymous_id: "dev:notifications", recipient_ids: [reader.id],
                                   recipient_properties: {}
        )
      end
    end

    describe ".read_all" do
      it "sends the reader and the read_at watermark" do
        read_at = Time.zone.parse("2026-11-20T16:10:44.017Z")

        described_class.read_all(user_id: reader.id, read_at: read_at)

        expect(Trackable::BatchEvent).to have_received(:enqueue).with(
          "notifications_read",
          properties: {
            "schema_version" => 1, "occurred_at" => "2026-11-20T16:10:44.017Z", "user_id" => reader.id,
            "read_at" => "2026-11-20T16:10:44.017Z", "scope" => "all", "recipient_user_ids" => nil,
            "notification_ids" => nil
          },
          anonymous_id: "dev:notifications",
          recipient_ids: [reader.id],
          recipient_properties: {},
        )
      end
    end

    describe ".read_one" do
      it "names the row that was read" do
        described_class.read_one(notification_for(reader, id: 99))

        expect(Trackable::BatchEvent).to have_received(:enqueue).with(
          "notifications_read",
          properties: hash_including("scope" => "notification", "notifiable_type" => "Article",
                                     "notifiable_id" => article.id, "action" => "Published"),
          anonymous_id: "dev:notifications",
          recipient_ids: [reader.id],
          recipient_properties: { "notification_ids" => [99] },
        )
      end
    end

    describe ".debounce" do
      it "schedules the debounce worker a minute out" do
        sidekiq_assert_enqueued_with(job: Notifications::SyncEventDebounceWorker,
                                     args: [reader.id, "Article", article.id, "Reaction"]) do
          described_class.debounce(user_id: reader.id, notifiable_type: "Article", notifiable_id: article.id,
                                   action: "Reaction")
        end
        expect(Notifications::SyncEventDebounceWorker.jobs.last["at"]).to be_within(5).of(60.seconds.from_now.to_f)
      end

      it "skips organization receivers" do
        described_class.debounce(user_id: nil, notifiable_type: "Article", notifiable_id: article.id,
                                 action: "Reaction")

        expect(Notifications::SyncEventDebounceWorker.jobs).to be_empty
      end
    end
  end
end
