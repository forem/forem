require "rails_helper"

RSpec.describe ForemInstance, type: :model do
  describe "deployed_at" do
    before do
      allow(ENV).to receive(:[])
      described_class.instance_variable_set(:@deployed_at, nil)
    end

    after do
      described_class.instance_variable_set(:@deployed_at, nil)
    end

    it "sets the RELEASE_FOOTPRINT if present" do
      allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("A deploy date")
      expect(described_class.deployed_at).to eq(ApplicationConfig["RELEASE_FOOTPRINT"])
    end

    it "sets the HEROKU_RELEASE_CREATED_AT if the RELEASE_FOOTPRINT is not present" do
      allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("")
      allow(ENV).to receive(:[]).with("HEROKU_RELEASE_CREATED_AT").and_return("A deploy date set on Heroku")
      expect(described_class.deployed_at).to eq(ENV["HEROKU_RELEASE_CREATED_AT"])
    end

    it "sets to current time if HEROKU_RELEASE_CREATED_AT and RELEASE_FOOTPRINT are not present" do
      Timecop.freeze do
        allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("")
        allow(ENV).to receive(:[]).with("HEROKU_RELEASE_CREATED_AT").and_return("")
        expect(described_class.deployed_at).to eq(Time.current.to_s)
      end
    end
  end

  describe "latest_commit_id" do
    before do
      described_class.instance_variable_set(:@latest_commit_id, nil)
    end

    it "sets the FOREM_BUILD_SHA if present" do
      allow(ApplicationConfig).to receive(:[]).with("FOREM_BUILD_SHA").and_return("A commit id")
      stub_const("ENV", ENV.to_h.merge("HEROKU_SLUG_COMMIT" => ""))
      expect(described_class.latest_commit_id).to eq(ApplicationConfig["FOREM_BUILD_SHA"])
    end

    it "sets the HEROKU_RELEASE_CREATED_AT if the RELEASE_FOOTPRINT is not present" do
      allow(ApplicationConfig).to receive(:[]).with("FOREM_BUILD_SHA").and_return("")
      stub_const("ENV", ENV.to_h.merge("HEROKU_SLUG_COMMIT" => "A Commit ID set from Heroku"))
      expect(described_class.latest_commit_id).to eq(ENV["HEROKU_SLUG_COMMIT"])
    end
  end

  describe ".local?" do
    it "returns true if the .app_domain points to localhost" do
      allow(Settings::General).to receive(:app_domain).and_return("localhost:3000")

      expect(described_class.local?).to be(true)
    end

    it "returns false if the .app_domain points to a regular domain" do
      allow(Settings::General).to receive(:app_domain).and_return("forem.dev")

      expect(described_class.local?).to be(false)
    end
  end

  describe ".dev_to?" do
    it "returns true if the .app_domain is dev.to" do
      allow(Settings::General).to receive(:app_domain).and_return("dev.to")

      expect(described_class.dev_to?).to be(true)
    end

    it "returns false if the .app_domain is not dev.to" do
      allow(Settings::General).to receive(:app_domain).and_return("forem.dev")

      expect(described_class.dev_to?).to be(false)
    end
  end

  describe ".smtp_enabled?" do
    it "return false when no credential is provided" do
      expect(described_class.smtp_enabled?).to be(false)
    end

    it "returns true if user_name and password are present" do
      allow(Settings::SMTP).to receive(:user_name).and_return("something")
      allow(Settings::SMTP).to receive(:password).and_return("something")

      expect(described_class.smtp_enabled?).to be(true)
    end

    it "returns true if sendgrid api key is available" do
      ENV["SENDGRID_API_KEY"] = "something"
      expect(described_class.smtp_enabled?).to be(true)
      ENV["SENDGRID_API_KEY"] = nil
    end
  end
end
