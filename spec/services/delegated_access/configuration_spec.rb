require "rails_helper"

RSpec.describe DelegatedAccess::Configuration do
  let(:environment) do
    {
      "DELEGATED_ACCESS_ENABLED" => "true",
      "DELEGATED_ACCESS_ISSUER" => "https://api.example.test",
      "DELEGATED_ACCESS_AUDIENCE" => "https://community.example.test",
      "DELEGATED_ACCESS_IDENTITY_PROVIDER" => "mlh",
      "DELEGATED_ACCESS_OWNER_CLAIM" => "https://api.example.test/claims/dev_user_id",
      "DELEGATED_ACCESS_JWKS_URI" => "https://api.example.test/.well-known/jwks.json"
    }
  end

  it "does not require trust configuration when delegated access is disabled" do
    config = described_class.from_env({ "DELEGATED_ACCESS_ENABLED" => "false" })

    expect(config.enabled).to be false
    expect(config.verifier).to be_nil
  end

  it "builds an enabled verifier from exact issuer, resource, identity, owner, and JWKS settings" do
    config = described_class.from_env(environment)

    expect(config).to have_attributes(
      enabled: true,
      issuer: environment.fetch("DELEGATED_ACCESS_ISSUER"),
      audience: environment.fetch("DELEGATED_ACCESS_AUDIENCE"),
      identity_provider: environment.fetch("DELEGATED_ACCESS_IDENTITY_PROVIDER"),
      owner_claim: environment.fetch("DELEGATED_ACCESS_OWNER_CLAIM"),
      jwks_uri: environment.fetch("DELEGATED_ACCESS_JWKS_URI"),
    )
    expect(config.verifier).to be_a(DelegatedAccess::Verifier)
    expect(config).not_to respond_to(:key_id)
    expect(config).not_to respond_to(:public_key)
  end

  it "requires every trust and identity setting when enabled" do
    required_names = environment.keys - ["DELEGATED_ACCESS_ENABLED"]

    required_names.each do |name|
      expect { described_class.from_env(environment.except(name)) }.to raise_error(KeyError)
      expect { described_class.from_env(environment.merge(name => "")) }.to raise_error(ArgumentError)
    end
  end

  it "requires a strict boolean enable flag" do
    expect do
      described_class.from_env(environment.merge("DELEGATED_ACCESS_ENABLED" => "TRUE"))
    end.to raise_error(ArgumentError, /must be true or false/)
  end

  it "requires configured HTTPS issuer, owner-claim, and JWKS URIs" do
    %w[DELEGATED_ACCESS_ISSUER DELEGATED_ACCESS_OWNER_CLAIM DELEGATED_ACCESS_JWKS_URI].each do |name|
      expect do
        described_class.from_env(environment.merge(name => "http://api.example.test/value"))
      end.to raise_error(ArgumentError, /HTTPS URI/)
    end
  end

  it "requires positive numeric safety bounds" do
    %w[
      DELEGATED_ACCESS_JWKS_MAX_AGE_SECONDS
      DELEGATED_ACCESS_MAX_TOKEN_LIFETIME_SECONDS
    ].each do |name|
      expect { described_class.from_env(environment.merge(name => "0")) }.to raise_error(ArgumentError)
      expect { described_class.from_env(environment.merge(name => "invalid")) }.to raise_error(ArgumentError)
    end
  end

  it "exposes an immediate cache invalidation control" do
    config = described_class.from_env(environment)
    allow(config.verifier).to receive(:invalidate_cache!)

    config.invalidate_cache!

    expect(config.verifier).to have_received(:invalidate_cache!)
  end
end
