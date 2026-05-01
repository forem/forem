require "rails_helper"

RSpec.describe Trackers::CustomerioCdp do
  subject(:adapter) { described_class.new }

  describe "#enabled?" do
    it "is true when CUSTOMERIO_CDP_WRITE_KEY is present" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return("key123")

      expect(adapter.enabled?).to be true
    end

    it "is false when CUSTOMERIO_CDP_WRITE_KEY is unset" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return(nil)

      expect(adapter.enabled?).to be false
    end

    it "is false when CUSTOMERIO_CDP_WRITE_KEY is empty" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return("")

      expect(adapter.enabled?).to be false
    end
  end

  describe "#track" do
    # Segment::Analytics implements #track via method_missing, so instance_double's
    # signature verification fails on it. Plain double is the correct fallback here.
    let(:client) { double(track: nil) } # rubocop:disable RSpec/VerifiedDoubles

    before do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return("key123")
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_HOST").and_return(nil)
      allow(Segment::Analytics).to receive(:new).and_return(client)
    end

    it "constructs the client with the configured write key and default host" do
      adapter.track(event_name: "x", user_ids: [1], properties: {})

      expect(Segment::Analytics).to have_received(:new).with(
        write_key: "key123",
        host: "cdp.customer.io",
      )
    end

    it "uses CUSTOMERIO_CDP_HOST override when set" do
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_HOST").and_return("cdp-eu.customer.io")

      adapter.track(event_name: "x", user_ids: [1], properties: {})

      expect(Segment::Analytics).to have_received(:new).with(
        write_key: "key123",
        host: "cdp-eu.customer.io",
      )
    end

    it "calls client.track once per user_id" do
      adapter.track(event_name: "article_created", user_ids: [1, 2], properties: { "title" => "t" })

      expect(client).to have_received(:track).with(
        user_id: "1", event: "article_created", properties: { "title" => "t" }, timestamp: nil,
      )
      expect(client).to have_received(:track).with(
        user_id: "2", event: "article_created", properties: { "title" => "t" }, timestamp: nil,
      )
    end

    it "passes timestamp through" do
      ts = Time.iso8601("2026-05-01T12:00:00Z")
      adapter.track(event_name: "x", user_ids: [1], properties: {}, timestamp: ts)

      expect(client).to have_received(:track).with(hash_including(timestamp: ts))
    end

    it "stringifies user ids" do
      adapter.track(event_name: "x", user_ids: [42], properties: {})

      expect(client).to have_received(:track).with(hash_including(user_id: "42"))
    end

    it "memoizes the client across multiple calls on the same instance" do
      adapter.track(event_name: "x", user_ids: [1], properties: {})
      adapter.track(event_name: "y", user_ids: [2], properties: {})

      expect(Segment::Analytics).to have_received(:new).once
    end
  end

  it "inherits from Trackers::Base" do
    expect(described_class.ancestors).to include(Trackers::Base)
  end
end
