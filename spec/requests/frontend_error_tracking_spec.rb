require "rails_helper"

RSpec.describe "Frontend error tracking provider precedence and isolation" do
  let(:betterstack_dsn) { "https://token123@s2773094.eu-central-1a.betterstackdata.com/2775219" }
  let(:honeybadger_js_key) { "hb-js-key-456" }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
  end

  describe "GET / (application layout)" do
    it "renders only Better Stack tags and omits Honeybadger when both ENV vars are set",
       :aggregate_failures do
      allow(ApplicationConfig).to receive(:[]).with("BETTER_STACK_JS_ERRORS_DSN").and_return(betterstack_dsn)
      allow(ApplicationConfig).to receive(:[]).with("HONEYBADGER_JS_API_KEY").and_return(honeybadger_js_key)

      get "/"

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML5(response.body)

      bs_meta = doc.at_css('head meta[name="betterstack-errors-script"]')
      expect(bs_meta).to be_present
      expect(bs_meta["content"]).to include("betterstackErrorsClient")

      expect(doc.at_css('head meta[name="honeybadger-script"]')).to be_nil

      body = doc.at_css("body")
      expect(body["data-betterstack-errors-dsn"]).to eq(betterstack_dsn)
      expect(body["data-honeybadger-key"]).to be_nil
    end

    it "renders only Honeybadger tags when BETTER_STACK_JS_ERRORS_DSN is blank and HONEYBADGER_JS_API_KEY is set",
       :aggregate_failures do
      allow(ApplicationConfig).to receive(:[]).with("BETTER_STACK_JS_ERRORS_DSN").and_return("")
      allow(ApplicationConfig).to receive(:[]).with("HONEYBADGER_JS_API_KEY").and_return(honeybadger_js_key)

      get "/"

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML5(response.body)

      hb_meta = doc.at_css('head meta[name="honeybadger-script"]')
      expect(hb_meta).to be_present
      expect(hb_meta["content"]).to include("honeybadgerClient")

      expect(doc.at_css('head meta[name="betterstack-errors-script"]')).to be_nil

      body = doc.at_css("body")
      expect(body["data-honeybadger-key"]).to eq(honeybadger_js_key)
      expect(body["data-betterstack-errors-dsn"]).to be_nil
    end

    it "renders neither Better Stack nor Honeybadger tags when neither ENV var is configured", :aggregate_failures do
      allow(ApplicationConfig).to receive(:[]).with("BETTER_STACK_JS_ERRORS_DSN").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("HONEYBADGER_JS_API_KEY").and_return(nil)

      get "/"

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML5(response.body)

      expect(doc.at_css('head meta[name="betterstack-errors-script"]')).to be_nil
      expect(doc.at_css('head meta[name="honeybadger-script"]')).to be_nil

      body = doc.at_css("body")
      expect(body["data-betterstack-errors-dsn"]).to be_nil
      expect(body["data-honeybadger-key"]).to be_nil
    end
  end

  describe "GET /admin (admin layout)" do
    let(:admin) { create(:user, :super_admin) }

    before do
      sign_in admin
    end

    it "gives Better Stack strict precedence over Honeybadger in the admin layout", :aggregate_failures do
      allow(ApplicationConfig).to receive(:[]).with("BETTER_STACK_JS_ERRORS_DSN").and_return(betterstack_dsn)
      allow(ApplicationConfig).to receive(:[]).with("HONEYBADGER_JS_API_KEY").and_return(honeybadger_js_key)

      get "/admin"

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML5(response.body)

      expect(doc.at_css('head meta[name="betterstack-errors-script"]')).to be_present
      expect(doc.at_css('head meta[name="honeybadger-script"]')).to be_nil
      expect(doc.at_css("body")["data-betterstack-errors-dsn"]).to eq(betterstack_dsn)
      expect(doc.at_css("body")["data-honeybadger-key"]).to be_nil
    end

    it "omits both providers in the admin layout when neither ENV var is configured", :aggregate_failures do
      allow(ApplicationConfig).to receive(:[]).with("BETTER_STACK_JS_ERRORS_DSN").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("HONEYBADGER_JS_API_KEY").and_return(nil)

      get "/admin"

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML5(response.body)

      expect(doc.at_css('head meta[name="betterstack-errors-script"]')).to be_nil
      expect(doc.at_css('head meta[name="honeybadger-script"]')).to be_nil
      expect(doc.at_css("body")["data-betterstack-errors-dsn"]).to be_nil
      expect(doc.at_css("body")["data-honeybadger-key"]).to be_nil
    end
  end
end
