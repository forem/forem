require "rails_helper"

RSpec.describe Authentication::ExternalReturn, type: :service do
  def with_origins(value)
    original = ENV["FOREM_EXTERNAL_RETURN_ORIGINS"]
    ENV["FOREM_EXTERNAL_RETURN_ORIGINS"] = value
    yield
  ensure
    ENV["FOREM_EXTERNAL_RETURN_ORIGINS"] = original
  end

  let(:params) { { "continuation" => "cont-token_1" } }

  describe ".redirect_url_for" do
    it "builds the redirect from the allowlisted entry, carrying the continuation verbatim" do
      with_origins("https://auth.mlh.test/web/auth/oauth/forem_returns") do
        url = described_class.redirect_url_for(params)
        expect(url).to eq("https://auth.mlh.test/web/auth/oauth/forem_returns?continuation=cont-token_1")
      end
    end
    it "rejects allowlist entries whose scheme is not https" do
      with_origins("http://auth.mlh.test/web/auth/oauth/forem_returns") do
        expect(described_class.redirect_url_for(params)).to be_nil
      end
    end

    it "requires the configured origin's path to match exactly" do
      with_origins("https://auth.mlh.test/web/auth/oauth") do
        expect(described_class.redirect_url_for(params)).to be_nil
      end
      with_origins("https://auth.mlh.test/web/auth/oauth/forem_returns/extra") do
        expect(described_class.redirect_url_for(params)).to be_nil
      end
    end

    it "drops continuations outside the URL-safe token shape silently" do
      with_origins("https://auth.mlh.test/web/auth/oauth/forem_returns") do
        expect(described_class.redirect_url_for("continuation" => "bad token&evil=1")).to be_nil
        expect(described_class.redirect_url_for("continuation" => "")).to be_nil
      end
    end

    it "returns nil when no allowlist is configured" do
      with_origins("") do
        expect(described_class.redirect_url_for(params)).to be_nil
      end
    end

    it "returns nil for missing omniauth params" do
      with_origins("https://auth.mlh.test/web/auth/oauth/forem_returns") do
        expect(described_class.redirect_url_for(nil)).to be_nil
      end
    end
  end

  describe ".allowlisted_destination" do
    it "canonicalizes an exact allowlisted origin+path" do
      with_origins("https://auth.mlh.test/web/auth/oauth/forem_returns") do
        expect(described_class.allowlisted_destination("https://auth.mlh.test/web/auth/oauth/forem_returns?x=1"))
          .to eq("https://auth.mlh.test/web/auth/oauth/forem_returns")
      end
    end

    it "rejects wrong paths, wrong hosts, and relative values" do
      with_origins("https://auth.mlh.test/web/auth/oauth/forem_returns") do
        expect(described_class.allowlisted_destination("https://auth.mlh.test/web/auth/other")).to be_nil
        expect(described_class.allowlisted_destination("https://evil.example.com/web/auth/oauth/forem_returns")).to be_nil
        expect(described_class.allowlisted_destination("/web/auth/oauth/forem_returns")).to be_nil
        expect(described_class.allowlisted_destination(nil)).to be_nil
      end
    end
  end
end
