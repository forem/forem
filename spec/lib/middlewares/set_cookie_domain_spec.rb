require "rails_helper"

RSpec.describe Middlewares::SetCookieDomain do
  let(:app) { ->(env) { [200, env, ["OK"]] } }
  let(:middleware) { described_class.new(app) }

  describe "#call" do
    it "sets rack.session.options[:domain] to the registrable root domain without calling PublicSuffix.parse" do
      allow(Settings::General).to receive(:app_domain).and_return("community.example.co.uk")
      allow(PublicSuffix).to receive(:parse)

      env = { "rack.session.options" => {} }
      middleware.call(env)

      expect(PublicSuffix).not_to have_received(:parse)
      expect(env["rack.session.options"][:domain]).to eq(".example.co.uk")
    end

    it "returns the host unchanged when the configured domain is not a valid public suffix domain" do
      allow(Settings::General).to receive(:app_domain).and_return("localhost")
      allow(PublicSuffix).to receive(:parse)

      env = { "rack.session.options" => {} }
      middleware.call(env)

      expect(PublicSuffix).not_to have_received(:parse)
      expect(env["rack.session.options"][:domain]).to eq(".localhost")
    end

    it "falls back to PublicSuffix.parse for non-ASCII IDN domains" do
      allow(Settings::General).to receive(:app_domain).and_return("sub.example.公司.cn")

      env = { "rack.session.options" => {} }
      middleware.call(env)

      expect(env["rack.session.options"][:domain]).to eq(".example.公司.cn")
    end
  end
end
