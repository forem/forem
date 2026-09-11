require "rails_helper"

RSpec.describe DelegatedAccess::Verifier do
  let(:now) { Time.utc(2026, 9, 8, 12, 0, 0) }
  let(:signing_key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:key_id) { "current-key" }
  let(:issuer) { "https://api.example.test" }
  let(:audience) { "https://community.example.test" }
  let(:owner_claim) { "https://api.example.test/claims/dev_user_id" }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:jwks_client) { instance_double(DelegatedAccess::JwksClient) }
  let(:verifier) do
    described_class.new(
      issuer: issuer,
      audience: audience,
      owner_claim: owner_claim,
      jwks_client: jwks_client,
      maximum_token_lifetime: 60,
      jwks_cache_lifetime: 1,
      cache: cache,
    )
  end
  let(:claims) do
    {
      "iss" => issuer,
      "sub" => "core-user-123",
      "aud" => audience,
      "iat" => now.to_i,
      "nbf" => now.to_i,
      "exp" => now.to_i + 30,
      "jti" => "unique-token-id",
      owner_claim => "123"
    }
  end

  def public_jwk(key, id)
    JWT::JWK.new(key.public_key, id).export.transform_keys(&:to_s).merge(
      "use" => "sig",
      "alg" => "RS256",
    )
  end

  def jwks_document(*keys)
    { "keys" => keys }.to_json
  end

  def token(payload = claims, key: signing_key, id: key_id, algorithm: "RS256", headers: {})
    JWT.encode(payload, key, algorithm, { kid: id, typ: "at+jwt" }.merge(headers))
  end

  before do
    allow(ForemStatsClient).to receive(:increment)
    allow(jwks_client).to receive(:fetch).and_return(jwks_document(public_jwk(signing_key, key_id)))
  end

  around do |example|
    Timecop.freeze(now) { example.run }
  end

  it "returns bounded verified identity claims" do
    result = verifier.verify(token)

    expect(result).to have_attributes(subject: "core-user-123", owner_id: 123)
  end

  it "uses a fresh cached known key without another network request" do
    2.times { verifier.verify(token) }

    expect(jwks_client).to have_received(:fetch).once
    expect(ForemStatsClient).to have_received(:increment)
      .with("delegated_access.verification", tags: ["outcome:cache_hit"])
  end

  it "accepts a newly published key after the cache lifetime" do
    successor_key = OpenSSL::PKey::RSA.generate(2048)
    allow(jwks_client).to receive(:fetch).and_return(
      jwks_document(public_jwk(signing_key, key_id)),
      jwks_document(public_jwk(signing_key, key_id), public_jwk(successor_key, "successor-key")),
    )

    verifier.verify(token)
    result = Timecop.travel(now + 2.seconds) do
      verifier.verify(token(key: successor_key, id: "successor-key"))
    end

    expect(result.owner_id).to eq(123)
    expect(jwks_client).to have_received(:fetch).twice
  end

  it "rejects unknown keys without refreshing the cache" do
    unknown_key = OpenSSL::PKey::RSA.generate(2048)
    verifier.verify(token)

    2.times do |index|
      expect do
        verifier.verify(token(key: unknown_key, id: "unknown-#{index}"))
      end.to raise_error(DelegatedAccess::Errors::InvalidToken)
    end

    expect(jwks_client).to have_received(:fetch).once
  end

  it "fails with an unavailable trust dependency on a cold-cache fetch failure" do
    allow(jwks_client).to receive(:fetch).and_raise(DelegatedAccess::JwksClient::Error)

    expect { verifier.verify(token) }.to raise_error(DelegatedAccess::Errors::Unavailable)
  end

  it "does not use an expired cached key when refresh fails" do
    verifier.verify(token)
    allow(jwks_client).to receive(:fetch).and_raise(DelegatedAccess::JwksClient::Error)

    expect do
      Timecop.travel(now + 2.seconds) { verifier.verify(token) }
    end.to raise_error(DelegatedAccess::Errors::Unavailable)
  end

  it "does not reinterpret issuer-owned client or scope authorization context" do
    issuer_context = claims.merge("client_id" => "another-client", "scope" => "articles:write")

    expect(verifier.verify(token(issuer_context)).owner_id).to eq(123)
    expect(verifier.verify(token(claims)).owner_id).to eq(123)
  end

  it "does not contact the trust endpoint for an unknown key while the cache is fresh" do
    verifier.verify(token)
    allow(jwks_client).to receive(:fetch).and_raise(DelegatedAccess::JwksClient::Error)
    unknown_key = OpenSSL::PKey::RSA.generate(2048)

    expect do
      verifier.verify(token(key: unknown_key, id: "unknown-key"))
    end.to raise_error(DelegatedAccess::Errors::InvalidToken)
    expect(jwks_client).to have_received(:fetch).once
  end

  it "rejects malformed or attacker-directed protected headers before fetching keys" do
    invalid_tokens = [
      "not-a-jwt",
      token(id: ""),
      token(headers: { typ: "JWT" }),
      token(headers: { jku: "https://attacker.example/jwks" }),
      token(claims, key: "shared-secret", algorithm: "HS256"),
    ]

    invalid_tokens.each do |invalid_token|
      expect do
        verifier.verify(invalid_token)
      end.to raise_error(DelegatedAccess::Errors::InvalidToken)
    end
    expect(jwks_client).not_to have_received(:fetch)
  end

  it "rejects a signature that does not match the selected published key" do
    other_key = OpenSSL::PKey::RSA.generate(2048)

    expect do
      verifier.verify(token(key: other_key))
    end.to raise_error(DelegatedAccess::Errors::InvalidToken)
  end

  it "requires exact trust, purpose, identity, time, and profile claims" do
    invalid_claims = [
      claims.except("sub"),
      claims.except("iat"),
      claims.except("nbf"),
      claims.except("exp"),
      claims.except("jti"),
      claims.except(owner_claim),
      claims.merge("iss" => "https://other.example.test"),
      claims.merge("aud" => [audience]),
      claims.merge("sub" => ""),
      claims.merge("jti" => ""),
      claims.merge("iat" => now.to_f),
      claims.merge("iat" => now.to_i + 10),
      claims.merge("nbf" => now.to_i + 10),
      claims.merge("exp" => now.to_i),
      claims.merge("exp" => now.to_i + 61),
      claims.merge(owner_claim => "not-an-id"),
      claims.merge("sid" => "session-id"),
      claims.merge("nonce" => "id-token-nonce"),
    ]

    invalid_claims.each do |invalid_payload|
      expect do
        verifier.verify(token(invalid_payload))
      end.to raise_error(DelegatedAccess::Errors::InvalidToken)
    end
  end

  it "uses the jwt gem's JWK set parser and rejects unusable key sets" do
    weak_key = OpenSSL::PKey::RSA.generate(1024)
    weak_jwk = public_jwk(weak_key, "weak-key")
    private_jwk = public_jwk(signing_key, key_id).merge("d" => "private")
    duplicate_jwk = public_jwk(OpenSSL::PKey::RSA.generate(2048), key_id)
    invalid_documents = [
      "not-json",
      [].to_json,
      {}.to_json,
      { "keys" => [] }.to_json,
      { "keys" => ["not-an-object"] }.to_json,
      { "keys" => [public_jwk(signing_key, key_id).except("kid")] }.to_json,
      { "keys" => [public_jwk(signing_key, key_id).merge("use" => "enc")] }.to_json,
      { "keys" => [public_jwk(signing_key, key_id), duplicate_jwk] }.to_json,
      { "keys" => [weak_jwk] }.to_json,
      { "keys" => [private_jwk] }.to_json,
    ]

    invalid_documents.each do |document|
      allow(jwks_client).to receive(:fetch).and_return(document)

      expect { verifier.verify(token) }.to raise_error(DelegatedAccess::Errors::Unavailable)
    end
  end

  it "can invalidate cached public keys immediately" do
    verifier.verify(token)
    verifier.invalidate_cache!
    verifier.verify(token)

    expect(jwks_client).to have_received(:fetch).twice
  end
end
