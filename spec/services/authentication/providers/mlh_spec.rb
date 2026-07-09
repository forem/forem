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
      },
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

  describe "#new_user_data" do
    it "maps email and name, leaving users.mlh_username untouched" do
      data = provider.new_user_data
      expect(data).to eq(email: "test@example.com", name: "MLH User")
    end
  end

  describe "#existing_user_data" do
    it "updates nothing, leaving users.mlh_username untouched" do
      expect(provider.existing_user_data).to eq({})
    end
  end
end
