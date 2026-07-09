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

    # user_gdpr_deleted fires after the row is destroyed; resolving the email
    # by DB lookup alone would silently drop exactly the event whose point is
    # that the user no longer exists.
    it "falls back to the payload email when the user row is already gone" do
      deleted_id = user.id
      payload = { "id" => deleted_id, "email" => user.email }
      user.destroy!

      adapter.track(event_name: "user_gdpr_deleted", user_ids: [deleted_id], properties: payload)

      expect(client).to have_received(:track).with(
        user_id: payload["email"], event: "user_gdpr_deleted", properties: payload, timestamp: nil,
      )
    end

    it "skips entirely when the user is gone and the payload has no email" do
      deleted_id = user.id
      user.destroy!

      adapter.track(event_name: "user_gdpr_deleted", user_ids: [deleted_id], properties: { "id" => deleted_id })

      expect(client).not_to have_received(:track)
    end

    # DEV ids are not synced to Core yet, so people are identified by email.
    it "identifies users by their current email, not their DEV id" do
      adapter.track(event_name: "user_updated", user_ids: [user.id], properties: { "id" => user.id })

      expect(client).to have_received(:track).with(
        user_id: user.email, event: "user_updated", properties: { "id" => user.id }, timestamp: nil,
      )
    end

    it "calls client.track once per user" do
      other_user = create(:user)
      adapter.track(event_name: "article_created", user_ids: [user.id, other_user.id],
                    properties: { "title" => "t" })

      expect(client).to have_received(:track).with(hash_including(user_id: user.email))
      expect(client).to have_received(:track).with(hash_including(user_id: other_user.email))
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
