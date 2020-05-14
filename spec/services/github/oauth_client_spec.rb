require "rails_helper"

RSpec.describe Github::OauthClient, type: :service do
  describe "initialization" do
    it "raises ArgumentError if credentials are missing" do
      expect { described_class.new({}) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if access_token is empty" do
      expect { described_class.new({ access_token: "" }) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if client_id or client_secret are empty" do
      expect { described_class.new({ client_id: "value", client_secret: "" }) }.to raise_error(ArgumentError)
    end

    it "succeeds if access_token is present" do
      expect { described_class.new({ access_token: "value" }) }.not_to raise_error(ArgumentError)
    end

    it "succeeds if both client_id and client_secret are present" do
      expect { described_class.new({ client_id: "value", client_secret: "value" }) }.not_to raise_error(ArgumentError)
    end
  end
end
