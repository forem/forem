require "rails_helper"

RSpec.describe Authentication::Providers::Apple, type: :service do
  let(:email) { "appleuser@example.com" }
  let(:auth_payload) do
    OmniAuth::AuthHash.new({
      provider: "apple",
      uid: "123456",
      info: {
        email: email,
        first_name: first_name,
        last_name: last_name
      },
      extra: {
        raw_info: {}
      }
    })
  end
  let(:provider) { described_class.new(auth_payload) }

  describe "#new_user_data" do
    context "when both first_name and last_name are present" do
      let(:first_name) { "Ada" }
      let(:last_name) { "Lovelace" }

      it "constructs the localized name using fields from Apple" do
        user_data = provider.new_user_data
        expect(user_data[:name]).to eq("Ada Lovelace")
      end
    end

    context "when both first_name and last_name are omitted entirely (e.g. returning users or hidden emails)" do
      let(:first_name) { nil }
      let(:last_name) { nil }

      it "falls back cleanly to the generated deterministic user_nickname to prevent blank presence payload validation failures" do
        user_data = provider.new_user_data
        expect(user_data[:name]).to eq(provider.user_nickname)
        expect(user_data[:name]).to include("user_")
      end
    end
  end

  describe "#user_nickname" do
    context "when email is nil and name fields are present" do
      let(:email) { nil }
      let(:first_name) { "Ada" }
      let(:last_name) { "Lovelace" }

      it "falls back to hashing the provider uid without raising TypeError" do
        expected = ["ada", "lovelace", Digest::SHA512.hexdigest("123456")].join("_")[0...25]
        expect(provider.user_nickname).to eq(expected)
      end
    end

    context "when name fields would otherwise exceed the 25-character nickname limit" do
      let(:email) { nil }
      let(:first_name) { "Alexandrina" }
      let(:last_name) { "Bartholomewson" }

      it "truncates the name prefix so a non-empty uid hash suffix is preserved" do
        uid_hash = Digest::SHA512.hexdigest("123456")
        expected = ["alexandrina_bart", uid_hash].join("_")[0...25]
        expect(provider.user_nickname).to eq(expected)
        expect(provider.user_nickname).to end_with(uid_hash[0...8])
      end
    end

    context "when email, first_name, and last_name are all nil" do
      let(:email) { nil }
      let(:first_name) { nil }
      let(:last_name) { nil }

      it "falls back to hashing the provider uid with the user prefix" do
        expected = ["user", Digest::SHA512.hexdigest("123456")].join("_")[0...15]
        expect(provider.user_nickname).to eq(expected)
      end
    end
  end
end
