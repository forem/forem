require "rails_helper"

RSpec.describe Trackers::CustomerioCdp do
  subject(:adapter) { described_class.new }

  def stub_write_key(value)
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return(value)
  end

  describe "#enabled?" do
    it "is true when CUSTOMERIO_CDP_WRITE_KEY is present and the admin setting is on" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return("key123")
      Settings::General.customerio_cdp_enabled = true

      expect(adapter.enabled?).to be true
    end

    it "is false when CUSTOMERIO_CDP_WRITE_KEY is unset" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return(nil)
      Settings::General.customerio_cdp_enabled = true

      expect(adapter.enabled?).to be false
    end

    it "is false when CUSTOMERIO_CDP_WRITE_KEY is empty" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return("")
      Settings::General.customerio_cdp_enabled = true

      expect(adapter.enabled?).to be false
    end

    it "is false when the admin setting is off, even with a write key" do
      stub_write_key("wk_test")
      Settings::General.customerio_cdp_enabled = false

      expect(described_class.new.enabled?).to be(false)
    end

    it "is true when both the write key and the setting are present" do
      stub_write_key("wk_test")
      Settings::General.customerio_cdp_enabled = true

      expect(described_class.new.enabled?).to be(true)
    end

    it "is false when the write key is missing, even if the setting is on" do
      stub_write_key(nil)
      Settings::General.customerio_cdp_enabled = true

      expect(described_class.new.enabled?).to be(false)
    end
  end

  describe "#track" do
    # Segment::Analytics implements #track via method_missing, so instance_double's
    # signature verification fails on it. Plain double is the correct fallback here.
    let(:client) { double(track: nil) } # rubocop:disable RSpec/VerifiedDoubles
    let(:user) { create(:user) }

    before do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return("key123")
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_HOST").and_return(nil)
      allow(Segment::Analytics).to receive(:new).and_return(client)
    end

    it "constructs the client with the write key, default host, and the CDP batch path" do
      adapter.track(event_name: "x", user_ids: [user.id], properties: {})

      # Customer.io CDP does not implement analytics-ruby's default /v1/import path.
      expect(Segment::Analytics).to have_received(:new).with(
        write_key: "key123",
        host: "cdp.customer.io",
        path: "/v1/batch",
      )
    end

    it "uses CUSTOMERIO_CDP_HOST override when set" do
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_HOST").and_return("cdp-eu.customer.io")

      adapter.track(event_name: "x", user_ids: [user.id], properties: {})

      expect(Segment::Analytics).to have_received(:new).with(
        write_key: "key123",
        host: "cdp-eu.customer.io",
        path: "/v1/batch",
      )
    end

    # Identity follows the Segment spec: a stable dev-scoped anonymous_id on
    # every call; email is never an identity field (it travels in properties).
    it "identifies users by a stable dev-scoped anonymous id, never email" do
      adapter.track(event_name: "user_updated", user_ids: [user.id], properties: { "id" => user.id })

      expect(client).to have_received(:track).with(
        anonymous_id: "dev:#{user.id}", event: "forem_user_updated",
        properties: { "id" => user.id }, timestamp: nil
      )
    end

    it "adds the canonical MLH user id as user_id once the account is linked" do
      # The identity factory reads OmniAuth.config.mock_auth for auth_data_dump.
      omniauth_mock_mlh_payload
      create(:identity, user: user, provider: "mlh", uid: "01JZFAKEULID0000000000USER")

      adapter.track(event_name: "user_updated", user_ids: [user.id], properties: { "id" => user.id })

      expect(client).to have_received(:track).with(
        hash_including(anonymous_id: "dev:#{user.id}", user_id: "01JZFAKEULID0000000000USER"),
      )
    end

    # user_gdpr_deleted fires after the row is destroyed; the stable anonymous
    # id keeps it deliverable without any DB row, and the payload's
    # mlh_user_id (captured before destruction) preserves the person link.
    it "delivers destructive events for a destroyed user via the anonymous id" do
      deleted_id = user.id
      payload = { "id" => deleted_id, "email" => user.email, "mlh_user_id" => "01JZFAKEULID0000000000USER" }
      user.destroy!

      adapter.track(event_name: "user_gdpr_deleted", user_ids: [deleted_id], properties: payload)

      expect(client).to have_received(:track).with(
        anonymous_id: "dev:#{deleted_id}", user_id: "01JZFAKEULID0000000000USER",
        event: "forem_user_gdpr_deleted", properties: payload, timestamp: nil
      )
    end

    it "delivers destructive events anonymously when the payload has no mlh_user_id" do
      deleted_id = user.id
      user.destroy!

      adapter.track(event_name: "user_gdpr_deleted", user_ids: [deleted_id], properties: { "id" => deleted_id })

      expect(client).to have_received(:track).with(
        anonymous_id: "dev:#{deleted_id}", event: "forem_user_gdpr_deleted",
        properties: { "id" => deleted_id }, timestamp: nil
      )
    end

    # A straggler user_updated for a just-deleted user must NOT deliver — it
    # could resurrect state after a GDPR erasure. Only destructive events may
    # deliver without a live row.
    it "drops non-destructive events when the user row is gone" do
      deleted_id = user.id
      payload = { "id" => deleted_id, "email" => user.email }
      user.destroy!

      adapter.track(event_name: "user_updated", user_ids: [deleted_id], properties: payload)

      expect(client).not_to have_received(:track)
    end

    it "calls client.track once per user" do
      other_user = create(:user)
      adapter.track(event_name: "article_created", user_ids: [user.id, other_user.id],
                    properties: { "title" => "t" })

      expect(client).to have_received(:track).with(hash_including(anonymous_id: "dev:#{user.id}"))
      expect(client).to have_received(:track).with(hash_including(anonymous_id: "dev:#{other_user.id}"))
    end

    it "passes timestamp through" do
      ts = Time.iso8601("2026-05-01T12:00:00Z")
      adapter.track(event_name: "x", user_ids: [user.id], properties: {}, timestamp: ts)

      expect(client).to have_received(:track).with(hash_including(timestamp: ts))
    end

    it "skips ids that no longer resolve to a user" do
      adapter.track(event_name: "x", user_ids: [User.maximum(:id).to_i + 1], properties: {})

      expect(client).not_to have_received(:track)
    end

    it "memoizes the client across multiple calls on the same instance" do
      adapter.track(event_name: "x", user_ids: [user.id], properties: {})
      adapter.track(event_name: "y", user_ids: [user.id], properties: {})

      expect(Segment::Analytics).to have_received(:new).once
    end

    # Events from different environments/instances share one Customer.io
    # workspace, so APP_NAME namespaces them: "dev_prod_user_updated".
    describe "APP_NAME event prefixing" do
      it "prefixes the event name with APP_NAME when set" do
        allow(ApplicationConfig).to receive(:[]).with("APP_NAME").and_return("dev_prod")

        adapter.track(event_name: "user_updated", user_ids: [user.id], properties: { "id" => user.id })

        expect(client).to have_received(:track).with(hash_including(event: "dev_prod_user_updated"))
      end

      it "falls back to the 'forem' prefix when APP_NAME is unset" do
        allow(ApplicationConfig).to receive(:[]).with("APP_NAME").and_return(nil)

        adapter.track(event_name: "user_updated", user_ids: [user.id], properties: { "id" => user.id })

        expect(client).to have_received(:track).with(hash_including(event: "forem_user_updated"))
      end

      it "falls back to the 'forem' prefix when APP_NAME is blank" do
        allow(ApplicationConfig).to receive(:[]).with("APP_NAME").and_return("")

        adapter.track(event_name: "user_updated", user_ids: [user.id], properties: { "id" => user.id })

        expect(client).to have_received(:track).with(hash_including(event: "forem_user_updated"))
      end

      # DESTRUCTIVE_EVENTS matches on the raw event name (before prefixing), so
      # a destroyed user's event still delivers — just under the namespaced name.
      it "prefixes destructive events while still delivering them" do
        allow(ApplicationConfig).to receive(:[]).with("APP_NAME").and_return("dev_prod")
        deleted_id = user.id
        user.destroy!

        adapter.track(event_name: "user_gdpr_deleted", user_ids: [deleted_id], properties: { "id" => deleted_id })

        expect(client).to have_received(:track).with(hash_including(event: "dev_prod_user_gdpr_deleted"))
      end
    end
  end

  describe "#track_batch" do
    let(:client) { double(track: nil) } # rubocop:disable RSpec/VerifiedDoubles
    let(:linked) { create_list(:user, 3) }
    let(:unlinked) { create(:user) }
    let(:properties) { { "schema_version" => 1, "kind" => "comment" } }

    before do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return("key123")
      allow(ApplicationConfig).to receive(:[]).with("APP_NAME").and_return("dev_prod")
      allow(Segment::Analytics).to receive(:new).and_return(client)
      linked.each_with_index { |user, i| create(:identity, provider: "mlh", user: user, uid: "core-#{i}") }
    end

    def batch(recipient_ids, recipient_properties = {})
      adapter.track_batch(
        event_name: "notifications_sent", properties: properties,
        anonymous_id: "dev:notifications", recipient_ids: recipient_ids, recipient_properties: recipient_properties
      )
    end

    it "sends one call under the fixed anonymous id with only MLH-linked recipients, ascending" do
      batch([unlinked.id] + linked.map(&:id).reverse)

      expect(client).to have_received(:track).once.with(
        anonymous_id: "dev:notifications",
        event: "dev_prod_notifications_sent",
        properties: properties.merge(
          "recipient_user_ids" => linked.map(&:id).sort, "chunk_index" => 0, "chunk_count" => 1,
        ),
        timestamp: nil,
      )
    end

    it "keeps each recipient property aligned with its recipient through filtering, dedup and sorting" do
      ids = linked.map(&:id).sort
      batch([ids[2], unlinked.id, ids[0], ids[1], ids[0]], { "notification_ids" => [302, 999, 300, 301, 888] })

      expect(client).to have_received(:track).once.with(hash_including(properties: hash_including(
        "recipient_user_ids" => ids, "notification_ids" => [300, 301, 302],
      )))
    end

    it "never sends a user id in the envelope" do
      batch(linked.map(&:id))

      expect(client).not_to have_received(:track).with(hash_including(:user_id))
    end

    it "sends nothing when no recipient is linked" do
      batch([unlinked.id])

      expect(client).not_to have_received(:track)
    end

    it "splits recipients into chunks of MAX_BATCH_RECIPIENTS" do
      stub_const("#{described_class}::MAX_BATCH_RECIPIENTS", 2)

      batch(linked.map(&:id))

      ids = linked.map(&:id).sort
      expect(client).to have_received(:track).with(hash_including(properties: hash_including(
        "recipient_user_ids" => ids.first(2), "chunk_index" => 0, "chunk_count" => 2,
      )))
      expect(client).to have_received(:track).with(hash_including(properties: hash_including(
        "recipient_user_ids" => ids.last(1), "chunk_index" => 1, "chunk_count" => 2,
      )))
    end

    it "halves a chunk while its properties exceed the byte budget" do
      single_size = properties.merge("recipient_user_ids" => [linked.first.id]).to_json.bytesize
      stub_const("#{described_class}::MAX_BATCH_PROPERTIES_BYTES", single_size + 1)

      batch(linked.map(&:id))

      expect(client).to have_received(:track).exactly(3).times
      expect(client).to have_received(:track).with(hash_including(properties: hash_including("chunk_count" => 3)))
        .exactly(3).times
    end

    it "sends properties unchanged, without filtering, when the event names no recipients" do
      batch(nil)

      expect(client).to have_received(:track).once.with(
        anonymous_id: "dev:notifications", event: "dev_prod_notifications_sent", properties: properties, timestamp: nil,
      )
    end
  end

  describe "#flush" do
    it "flushes the client's in-memory queue" do
      client = double(track: nil, flush: nil) # rubocop:disable RSpec/VerifiedDoubles
      allow(Segment::Analytics).to receive(:new).and_return(client)
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return("key123")
      adapter.track_batch(event_name: "x", properties: {}, anonymous_id: "dev:notifications")

      adapter.flush

      expect(client).to have_received(:flush)
    end

    it "does nothing before any call built the client" do
      allow(Segment::Analytics).to receive(:new)

      adapter.flush

      expect(Segment::Analytics).not_to have_received(:new)
    end
  end

  it "inherits from Trackers::Base" do
    expect(described_class.ancestors).to include(Trackers::Base)
  end
end
