require "rails_helper"

RSpec.describe Authentication::Providers::Mlh, type: :service do
  let(:auth_payload) do
    OmniAuth::AuthHash.new(
      provider: "mlh",
      uid: "123456",
      info: {
        email: "test@example.com",
        nickname: "mlhuser",
        name: "MLH User"
      },
      extra: {
        raw_info: {}
      }
    )
  end
  let(:provider) { described_class.new(auth_payload) }

  describe ".official_name" do
    it "returns MyMLH" do
      expect(described_class.official_name).to eq("MyMLH")
    end
  end

  describe ".sign_in_path" do
    it "returns the correct sign in path without callback_url param" do
      path = described_class.sign_in_path
      expect(path).to include("/users/auth/mlh")
      expect(path).not_to include("callback_url=")
    end

    it "supports additional parameters" do
      path = described_class.sign_in_path(state: "mystate")
      expect(path).to include("state=mystate")
    end
  end

  describe ".user_username_field" do
    it "is nil because the MLH link lives on the identity (uid = Core user id), not a users column" do
      expect(described_class.user_username_field).to be_nil
    end
  end

  describe "#new_user_data" do
    it "maps the correct data for a new user, seeding the username from the nickname" do
      data = provider.new_user_data
      expect(data).to eq(email: "test@example.com", name: "MLH User", provider_username_seed: "mlhuser")
    end
  end

  describe "#existing_user_data" do
    it "has no user columns to refresh" do
      expect(provider.existing_user_data).to eq({})
    end
  end
end
