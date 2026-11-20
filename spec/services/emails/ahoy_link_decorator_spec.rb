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

  describe "external links" do
    it "routes them through the mounted Ahoy engine, as the SMTP path does" do
      result = decorate({ "url" => "https://example.com/post" })

      expect(result["url"]).to include("/ahoy/click?")
      expect(params_from(result["url"])["u"]).to eq("https://example.com/post")
    end
  end

  # A tracked URL pasted back into stored content arrives looking like an
  # ordinary internal link. Decorating it again appends a second t/s/u set, and
  # since Rack resolves duplicate params to the last value, the engine verifies
  # the outer signature and redirects to itself.
  describe "links that already carry tracking" do
    it "leaves an ahoy_click URL alone" do
      tracked = "https://#{domain}/post?ahoy_click=true&t=old&s=sig&u=x"
      expect(decorate({ "url" => tracked })["url"]).to eq(tracked)
    end

    it "leaves an engine redirect URL alone" do
      tracked = "https://#{domain}/ahoy/click?t=old&s=sig&u=https%3A%2F%2Fexample.com"
      expect(decorate({ "url" => tracked })["url"]).to eq(tracked)
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

  describe "out-of-domain fallbacks and campaign handling" do
    it "preserves campaign parameter semantics on internal and external links" do
      with_campaign = decorate(
        { "internal" => article_url, "external" => "https://example.com/post" },
        data: { token: token, campaign: "digest" },
      )
      expect(params_from(with_campaign["internal"])["c"]).to eq("digest")
      expect(params_from(with_campaign["external"])["c"]).to eq("digest")

      with_empty_campaign = decorate(
        { "internal" => article_url, "external" => "https://example.com/post" },
        data: { token: token, campaign: "" },
      )
      expect(params_from(with_empty_campaign["internal"])).not_to have_key("c")
      expect(params_from(with_empty_campaign["external"])["c"]).to eq("")
    end

    it "falls back transparently for HTML containing comments and schemeless heuristic URLs" do
      payload = {
        "commented_html" => %(<!-- comment --><a href="#{article_url}">Read</a>),
        "heuristic" => "example.com/post"
      }
      native_returns = []
      allow(ForemNative).to receive(:ahoy_decorate_payload).and_wrap_original do |original, *args|
        res = original.call(*args)
        native_returns << res
        res
      end

      result = decorate(payload)

      expect(native_returns).to eq([nil])
      href = Nokogiri::HTML::DocumentFragment.parse(result["commented_html"]).at_css("a")["href"]
      expect(params_from(href)["ahoy_click"]).to eq("true")
      expect(result["heuristic"]).to include("/ahoy/click?")
      expect(params_from(result["heuristic"])["u"]).to eq("example.com/post")
    end

    it "preserves HashWithIndifferentAccess payload classes via Ruby fallback" do
      payload = { "url" => article_url }.with_indifferent_access
      result = decorate(payload)

      expect(result).to be_a(ActiveSupport::HashWithIndifferentAccess)
      expect(params_from(result[:url])["ahoy_click"]).to eq("true")
    end

    it "preserves compare_by_identity hashes via Ruby fallback" do
      payload = {}.compare_by_identity
      k1 = +"url"
      k2 = +"url"
      payload[k1] = article_url
      payload[k2] = "https://example.com/post"
      result = decorate(payload)

      expect(result.compare_by_identity?).to be(true)
      expect(result.size).to eq(2)
      expect(params_from(result[k1])["ahoy_click"]).to eq("true")
      expect(result[k2]).to include("/ahoy/click?")
    end

    it "reads fresh mailer url_options on repeated calls to the same decorator instance" do
      decorator = described_class.new({ "ext" => "https://example.com/post" }, ahoy_data)
      original_options = ActionMailer::Base.default_url_options
      begin
        ActionMailer::Base.default_url_options = { host: "first.example.test", protocol: "https" }
        first = decorator.call
        ActionMailer::Base.default_url_options = { host: "second.example.test", protocol: "https" }
        second = decorator.call

        expect(first["ext"]).to start_with("https://first.example.test/ahoy/click?")
        expect(second["ext"]).to start_with("https://second.example.test/ahoy/click?")
      ensure
        ActionMailer::Base.default_url_options = original_options
      end
    end

    it "defers non-standard external url_options without breaking internal link tracking" do
      expect(Emails::AhoyLinkTracking.external_base_url({ 1 => "bad", :host => "dev.to" })).to be_nil
      expect(Emails::AhoyLinkTracking.external_base_url({ host: "dev.to", protocol: false })).to be_nil
      expect(
        Emails::AhoyLinkTracking.external_base_url({ host: "dev.to:8443", protocol: "https", port: 9443 }),
      ).to be_nil
      expect(
        Emails::AhoyLinkTracking.external_base_url({ host: "dev.to", protocol: "https", port: 9443 }),
      ).to eq("https://dev.to:9443/ahoy/click")
    end

    it "never injects attributes when rewriting single-quoted hrefs containing double quotes" do
      html = %(<a href='https://#{domain}/post"title="injected'>Read</a>)
      result = decorate({ "smart_summary" => html })
      anchor = Nokogiri::HTML::DocumentFragment.parse(result["smart_summary"]).at_css("a")

      expect(anchor.attributes.keys).to eq(["href"])
      expect(params_from(anchor["href"])["ahoy_click"]).to eq("true")
    end
  end
end
