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
    it "returns the correct sign in path with callback_url" do
      path = described_class.sign_in_path
      expect(path).to include("/users/auth/mlh")
      expect(path).to include("callback_url=")
      expect(path).to include("users%2Fauth%2Fmlh%2Fcallback")
    end

    it "supports additional parameters" do
      path = described_class.sign_in_path(state: "mystate")
      expect(path).to include("state=mystate")
    end
  end

  describe "#new_user_data" do
    it "maps the correct data for a new user" do
      data = provider.new_user_data
      expect(data[:email]).to eq("test@example.com")
      expect(data[:mlh_username]).to eq("mlhuser")
      expect(data[:name]).to eq("MLH User")
    end
  end

  describe "#existing_user_data" do
    it "maps the correct data for an existing user" do
      data = provider.existing_user_data
      expect(data[:mlh_username]).to eq("mlhuser")
    end
  end
end
