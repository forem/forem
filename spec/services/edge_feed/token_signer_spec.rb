require "rails_helper"

RSpec.describe EdgeFeed::TokenSigner, type: :service do
  let(:secret) { "test-fastly-edge-feed-secret" }
  let(:now) { Time.zone.at(1_750_000_000) }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_EDGE_FEED_SECRET").and_return(secret)
  end

  describe ".configured?" do
    it "returns true when FASTLY_EDGE_FEED_SECRET is present" do
      expect(described_class).to be_configured
    end

    it "returns false when FASTLY_EDGE_FEED_SECRET is blank" do
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_EDGE_FEED_SECRET").and_return(nil)
      expect(described_class).not_to be_configured
    end
  end

  describe ".issue_user_token and .verify_user_token" do
    it "round-trips a valid user_id before expiration" do
      token = described_class.issue_user_token(user_id: 42, ttl: 1.hour, now: now)

      expect(token).to start_with("eu1.")
      expect(described_class.verify_user_token(token, now: now + 30.minutes)).to eq(42)
    end

    it "rejects expired, tampered, wrong-prefix, or wrong-secret tokens", :aggregate_failures do
      token = described_class.issue_user_token(user_id: 42, ttl: 1.hour, now: now)

      expect(described_class.verify_user_token(token, now: now + 2.hours)).to be_nil
      expect(described_class.verify_user_token(token, now: now, secret: "other-secret")).to be_nil

      tampered = "#{token[0..-2]}#{token[-1] == 'a' ? 'b' : 'a'}"
      expect(described_class.verify_user_token(tampered, now: now)).to be_nil

      visit_token = described_class.issue_visit_token(
        user_id: 42, subforem_id: 1, feed_config_id: 7, expires_at: now + 1.hour, host: "dev.to",
      )
      expect(described_class.verify_user_token(visit_token, now: now)).to be_nil
    end
  end

  describe ".issue_visit_token and .verify_visit_token" do
    it "round-trips a valid edge visit token payload" do
      expires_at = now + 2.hours
      token = described_class.issue_visit_token(
        user_id: 42, subforem_id: 3, feed_config_id: 99, expires_at: expires_at, host: "dev.to",
      )

      expect(token).to start_with("ev1.")
      verified = described_class.verify_visit_token(token, now: now)
      expect(verified).to eq(
        "user_id" => 42,
        "subforem_id" => 3,
        "feed_config_id" => 99,
        "expires_at" => expires_at.utc,
        "host" => "dev.to",
      )
    end

    it "rejects expired edge visit tokens" do
      token = described_class.issue_visit_token(
        user_id: 42, subforem_id: 3, feed_config_id: 99, expires_at: now - 1.minute, host: "dev.to",
      )

      expect(described_class.verify_visit_token(token, now: now)).to be_nil
    end
  end

  describe ".set_user_cookie and .clear_user_cookie" do
    it "sets an HttpOnly SameSite=Lax cookie and clears both edge cookies" do
      jar = {}
      described_class.set_user_cookie(jar, user_id: 42, secure: true)

      cookie = jar[described_class::USER_COOKIE_NAME]
      expect(cookie[:httponly]).to be(true)
      expect(cookie[:same_site]).to eq(:lax)
      expect(cookie[:secure]).to be(true)
      expect(described_class.verify_user_token(cookie[:value])).to eq(42)

      jar[described_class::STICKY_CONFIG_COOKIE_NAME] = "ec1.foo.bar"
      described_class.clear_user_cookie(jar)
      expect(jar).to be_empty
    end
  end
end
