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
end
