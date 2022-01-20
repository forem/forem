require "rails_helper"

RSpec.describe Settings::SMTP do
  let(:key) { "something" }

  before { ENV["SENDGRID_API_KEY"] = key }

  after do
    described_class.clear_cache
    ENV["SENDGRID_API_KEY"] = nil
  end

  describe "::settings" do
    it "use falback sendgrid settings if address is not provided" do
      domain = "test.com"
      allow(Settings::General).to receive(:app_domain).and_return(domain)

      expect(described_class.settings).to eq({
                                               address: "smtp.sendgrid.net",
                                               port: 587,
                                               authentication: :plain,
                                               user_name: "apikey",
                                               password: key,
                                               domain: domain
                                             })
    end

    it "uses Settings::SMTP config if address is provided" do
      described_class.address = "smtp.google.com"
      described_class.port = 25
      described_class.authentication = "plain"
      described_class.user_name = "username"
      described_class.password = "password"
      described_class.domain = "forem.local"

      expect(described_class.settings).to eq({
                                               address: "smtp.google.com",
                                               port: 25,
                                               authentication: "plain",
                                               user_name: "username",
                                               password: "password",
                                               domain: "forem.local"
                                             })
    end
  end

  describe "::provided_minimum_settings?" do
    it "returns true if addess, user_name, and password are provided" do
      described_class.address = "smtp.google.com"
      described_class.user_name = "username"
      described_class.password = "password"

      expect(described_class.provided_minimum_settings?).to be true
    end

    it "returns false if one of addess, user_name, or password is missing" do
      described_class.address = "smtp.google.com"

      expect(described_class.provided_minimum_settings?).to be false
    end
  end
end
