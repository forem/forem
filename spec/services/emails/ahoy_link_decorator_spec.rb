require "rails_helper"

RSpec.describe Emails::AhoyLinkDecorator, type: :service do
  let(:token) { "abc123token" }
  let(:ahoy_data) { { token: token, campaign: nil } }
  let(:domain) { Settings::General.app_domain }
  let(:article_url) { "https://#{domain}/ben/some-post?context=digest" }

  def decorate(payload, data: ahoy_data)
    described_class.call(payload, ahoy_data: data)
  end

  def params_from(url)
    Rack::Utils.parse_query(Addressable::URI.parse(url).query)
  end

  describe "internal links" do
    it "appends the tracking params baseTracking.js looks for" do
      result = decorate({ "url" => article_url })
      params = params_from(result["url"])

      expect(params["ahoy_click"]).to eq("true")
      expect(params["t"]).to eq(token)
      expect(params["s"]).to be_present
    end

    it "keeps the original destination and its existing query params" do
      result = decorate({ "url" => article_url })

      expect(result["url"]).to start_with("https://#{domain}/ben/some-post?")
      expect(params_from(result["url"])["context"]).to eq("digest")
    end

    # The click URL survives two decodes before EmailClicksController verifies
    # it: URLSearchParams.get decodes once and baseTracking.js calls
    # decodeURIComponent on the result. Signing over anything else makes
    # verify_signature reject every click.
    it "produces a signature that verify_signature accepts after both decodes" do
      result = decorate({ "url" => article_url })
      params = params_from(result["url"])

      round_tripped = CGI.unescape(params["u"])
      expected = AhoyEmail::Utils.signature(
        token: params["t"], campaign: params["c"].to_s, url: round_tripped,
      )

      expect(round_tripped).to eq(article_url)
      expect(params["s"]).to eq(expected)
    end

    it "survives a destination that itself contains encoded characters" do
      tricky = "https://#{domain}/search?q=100%25%20ruby"
      result = decorate({ "url" => tricky })
      params = params_from(result["url"])

      expect(CGI.unescape(params["u"])).to eq(tricky)
    end
  end

  describe "HTML values" do
    it "decorates anchors inside rendered HTML" do
      html = %(<div><a href="#{article_url}">Read</a></div>)
      result = decorate({ "smart_summary" => html })

      href = Nokogiri::HTML::DocumentFragment.parse(result["smart_summary"]).at_css("a")["href"]
      expect(params_from(href)["ahoy_click"]).to eq("true")
    end

    it "preserves a billboard's bb param so click attribution still resolves" do
      html = %(<a href="https://#{domain}/sponsor?bb=42">Ad</a>)
      result = decorate({ "billboards_html" => { "first" => html } })

      href = Nokogiri::HTML::DocumentFragment.parse(result["billboards_html"]["first"]).at_css("a")["href"]
      expect(params_from(href)["bb"]).to eq("42")
      expect(params_from(href)["ahoy_click"]).to eq("true")
    end

    it "honours data-skip-click" do
      html = %(<a href="#{article_url}" data-skip-click="true">Read</a>)
      result = decorate({ "smart_summary" => html })

      href = Nokogiri::HTML::DocumentFragment.parse(result["smart_summary"]).at_css("a")["href"]
      expect(href).to eq(article_url)
    end
  end

  describe "links it leaves alone" do
    it "skips unsubscribe links" do
      url = "https://#{domain}/email_subscriptions/unsubscribe?ut=xyz"
      expect(decorate({ "unsubscribe_url" => url })["unsubscribe_url"]).to eq(url)
    end

    it "leaves plain strings untouched" do
      payload = { "subject" => "A post you might like", "name" => "Ben" }
      expect(decorate(payload)).to eq(payload)
    end

    it "leaves non-http schemes untouched" do
      expect(decorate({ "x" => "mailto:yo@example.com" })["x"]).to eq("mailto:yo@example.com")
    end
  end

  # The SMTP path sends these through the mounted AhoyEmail engine, but that
  # redirect URL is built from default_url_options, whose :host already carries
  # the protocol in production. Reproducing it would emit broken links, and an
  # external click only ever set clicked_at anyway.
  describe "external links" do
    it "leaves them untouched" do
      expect(decorate({ "url" => "https://example.com/post" })["url"])
        .to eq("https://example.com/post")
    end
  end

  describe "when tracking is unavailable" do
    it "returns the payload unchanged without a token" do
      payload = { "url" => article_url }
      expect(decorate(payload, data: { campaign: nil })).to eq(payload)
    end

    it "returns the payload unchanged when ahoy_data is nil" do
      payload = { "url" => article_url }
      expect(decorate(payload, data: nil)).to eq(payload)
    end

    # A tracking failure must never cost us the send.
    it "falls back to the undecorated payload if decoration raises" do
      allow(AhoyEmail::Utils).to receive(:signature).and_raise(StandardError, "boom")
      payload = { "url" => article_url }

      expect(decorate(payload)).to eq(payload)
    end
  end

  it "recurses through nested hashes and arrays" do
    payload = { "articles" => [{ "url" => article_url }, { "url" => article_url }] }
    result = decorate(payload)

    result["articles"].each do |article|
      expect(params_from(article["url"])["ahoy_click"]).to eq("true")
    end
  end
end
