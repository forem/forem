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
        anonymous_id: "dev:#{user.id}", event: "user_updated",
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
        event: "user_gdpr_deleted", properties: payload, timestamp: nil
      )
    end

    it "delivers destructive events anonymously when the payload has no mlh_user_id" do
      deleted_id = user.id
      user.destroy!

      adapter.track(event_name: "user_gdpr_deleted", user_ids: [deleted_id], properties: { "id" => deleted_id })

      expect(client).to have_received(:track).with(
        anonymous_id: "dev:#{deleted_id}", event: "user_gdpr_deleted",
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
  end

  it "inherits from Trackers::Base" do
    expect(described_class.ancestors).to include(Trackers::Base)
  end
end
