require "rails_helper"

RSpec.describe Identity, type: :model do
  let(:identity) { create(:identity, user: create(:user), uid: SecureRandom.hex) }

  describe "validations" do
    describe "builtin validations" do
      subject { identity }

      it { is_expected.to belong_to(:user) }

      it { is_expected.to validate_presence_of(:provider) }
      it { is_expected.to validate_presence_of(:uid) }
      it { is_expected.to validate_presence_of(:user_id) }
      it { is_expected.to validate_uniqueness_of(:uid).scoped_to(:provider) }
      it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:provider) }

      it { is_expected.to validate_inclusion_of(:provider).in_array(Authentication::Providers.available.map(&:to_s)) }

      it { is_expected.to serialize(:auth_data_dump) }
    end
  end

  describe ".build_build_from_omniauth" do
    let(:user) { create(:user) }

    before do
      omniauth_mock_providers_payload
    end

    context "with Apple payload" do
      let(:auth_payload) { OmniAuth.config.mock_auth[:apple] }
      let(:provider) { Authentication::Providers::Apple.new(auth_payload) }

      it "initializes a new identity from the auth payload" do
        identity = described_class.build_from_omniauth(provider)

        expect(identity.new_record?).to be(true)
        expect(identity.provider).to eq("apple")
        expect(identity.uid).to eq(auth_payload.uid)
        expect(identity.token).to eq(auth_payload.credentials.token)
        expect(identity.secret).to be_nil
        expect(identity.auth_data_dump).to eq(provider.payload)
      end

      it "finds an existing identity" do
        payload = provider.payload

        existing_identity = described_class.create!(
          user: user,
          provider: payload.provider,
          uid: payload.uid,
          token: payload.credentials.token,
          secret: nil,
          auth_data_dump: payload,
        )

        identity = described_class.build_from_omniauth(provider)
        expect(identity).to eq(existing_identity)
      end
    end

    context "with Github payload" do
      let(:auth_payload) { OmniAuth.config.mock_auth[:github] }
      let(:provider) { Authentication::Providers::Github.new(auth_payload) }

      it "initializes a new identity from the auth payload" do
        identity = described_class.build_from_omniauth(provider)

        expect(identity.new_record?).to be(true)
        expect(identity.provider).to eq("github")
        expect(identity.uid).to eq(auth_payload.uid)
        expect(identity.token).to eq(auth_payload.credentials.token)
        expect(identity.secret).to eq(auth_payload.credentials.secret)
        expect(identity.auth_data_dump).to eq(provider.payload)
      end

      it "finds an existing identity" do
        payload = provider.payload

        existing_identity = described_class.create!(
          user: user,
          provider: payload.provider,
          uid: payload.uid,
          token: payload.credentials.token,
          secret: payload.credentials.secret,
          auth_data_dump: payload,
        )

        identity = described_class.build_from_omniauth(provider)
        expect(identity).to eq(existing_identity)
      end
    end

    context "with Facebook payload" do
      let(:auth_payload) { OmniAuth.config.mock_auth[:facebook] }
      let(:provider) { Authentication::Providers::Facebook.new(auth_payload) }

      it "initializes a new identity from the auth payload" do
        identity = described_class.build_from_omniauth(provider)

        expect(identity.new_record?).to be(true)
        expect(identity.provider).to eq("facebook")
        expect(identity.uid).to eq(auth_payload.uid)
        expect(identity.token).to eq(auth_payload.credentials.token)
        expect(identity.secret).to eq(auth_payload.credentials.secret)
        expect(identity.auth_data_dump).to eq(provider.payload)
      end

      it "finds an existing identity" do
        payload = provider.payload

        existing_identity = described_class.create!(
          user: user,
          provider: payload.provider,
          uid: payload.uid,
          token: payload.credentials.token,
          secret: payload.credentials.secret,
          auth_data_dump: payload,
        )

        identity = described_class.build_from_omniauth(provider)
        expect(identity).to eq(existing_identity)
      end
    end

    context "with Forem payload" do
      let(:auth_payload) { OmniAuth.config.mock_auth[:forem] }
      let(:provider) { Authentication::Providers::Forem.new(auth_payload) }

      it "initializes a new identity from the auth payload" do
        identity = described_class.build_from_omniauth(provider)

        expect(identity.new_record?).to be(true)
        expect(identity.provider).to eq("forem")
        expect(identity.uid).to eq(auth_payload.uid)
        expect(identity.token).to eq(auth_payload.credentials.token)
        expect(identity.secret).to eq(auth_payload.credentials.secret)
        expect(identity.auth_data_dump).to eq(provider.payload)
      end

      it "finds an existing identity" do
        payload = provider.payload

        existing_identity = described_class.create!(
          user: user,
          provider: payload.provider,
          uid: payload.uid,
          token: payload.credentials.token,
          secret: payload.credentials.secret,
          auth_data_dump: payload,
        )

        identity = described_class.build_from_omniauth(provider)
        expect(identity).to eq(existing_identity)
      end
    end

    context "with Twitter payload" do
      let(:auth_payload) { OmniAuth.config.mock_auth[:twitter] }
      let(:provider) { Authentication::Providers::Twitter.new(auth_payload) }

      it "initializes a new identity from the auth payload" do
        identity = described_class.build_from_omniauth(provider)

        expect(identity.new_record?).to be(true)
        expect(identity.provider).to eq("twitter")
        expect(identity.uid).to eq(auth_payload.uid)
        expect(identity.token).to eq(auth_payload.credentials.token)
        expect(identity.secret).to eq(auth_payload.credentials.secret)
        expect(identity.auth_data_dump).to eq(provider.payload)
      end

      it "finds an existing identity" do
        payload = provider.payload

        existing_identity = described_class.create!(
          user: user,
          provider: payload.provider,
          uid: payload.uid,
          token: payload.credentials.token,
          secret: payload.credentials.secret,
          auth_data_dump: payload,
        )

        identity = described_class.build_from_omniauth(provider)
        expect(identity).to eq(existing_identity)
      end

      it "does not store the access token in auth_data_dump" do
        expect(auth_payload.extra.access_token).not_to be_nil

        identity = described_class.build_from_omniauth(provider)

        expect(identity.auth_data_dump.extra.access_token).to be_nil
      end
    end
  end

  describe "#email" do
    let(:auth_payload) { OmniAuth.config.mock_auth[:github] }
    let(:provider) { Authentication::Providers::Github.new(auth_payload) }

    before do
      omniauth_mock_providers_payload
    end

    it "returns the email associated with the identity" do
      identity = described_class.build_from_omniauth(provider)
      expect(identity.email).to eq(identity.auth_data_dump.info.email)
    end
  end
end
