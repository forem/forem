require "rails_helper"

RSpec.describe Settings::SMTP do
  describe "::settings" do
    it "use default sendgrid config if SENDGRID_API_KEY is available" do
      key = "something"
      domain = "test.com"
      allow(ApplicationConfig).to receive(:[]).with("SENDGRID_API_KEY").and_return(key)
      ENV["SENDGRID_API_KEY"] = "something"
      allow(Settings::General).to receive(:app_domain).and_return(domain)

      expect(described_class.settings).to eq({
                                               address: "smtp.sendgrid.net",
                                               port: 587,
                                               authentication: :plain,
                                               user_name: "apikey",
                                               password: key,
                                               domain: domain
                                             })
      ENV["SENDGRID_API_KEY"] = nil
    end

    it "uses Settings::SMTP config if SENDGRID_API_KEY is not available" do
      described_class.address = "smtp.google.com"
      described_class.port = 25
      described_class.authentication = "plain"
      described_class.user_name = "username"
      described_class.password = "password"

      expect(described_class.settings).to eq({
                                               address: "smtp.google.com",
                                               port: 25,
                                               authentication: "plain",
                                               user_name: "username",
                                               password: "password",
                                               domain: ""
                                             })
    end
  end
end
