require "rails_helper"

RSpec.describe Authentication::ExternalReturn, type: :service do
  def with_return_url(value)
    original = ENV.fetch("FOREM_EXTERNAL_RETURN_URL", nil)
    ENV["FOREM_EXTERNAL_RETURN_URL"] = value
    yield
  ensure
    ENV["FOREM_EXTERNAL_RETURN_URL"] = original
  end

  around do |example|
    original = ENV.fetch("FOREM_EXTERNAL_RETURN_ENABLED", nil)
    ENV["FOREM_EXTERNAL_RETURN_ENABLED"] = "true"
    example.run
  ensure
    ENV["FOREM_EXTERNAL_RETURN_ENABLED"] = original
  end

  let(:params) { { "continuation" => "cont-token_1" } }

  describe "feature gate" do
    [nil, "", "false", "1", "TRUE"].each do |value|
      it "disables both return paths when the flag is #{value.inspect}", :aggregate_failures do
        ENV["FOREM_EXTERNAL_RETURN_ENABLED"] = value
        with_return_url("https://receiver.example/resume") do
          expect(described_class.redirect_url_for(params)).to be_nil
          expect(described_class.allowlisted_destination("https://receiver.example/resume")).to be_nil
        end
      end
    end
  end

  describe ".redirect_url_for" do
    it "builds the redirect from the allowlisted entry, carrying the continuation verbatim" do
      with_return_url("https://receiver.example/resume") do
        url = described_class.redirect_url_for(params)
        expect(url).to eq("https://receiver.example/resume?continuation=cont-token_1")
      end
    end

    it "requires a configured HTTPS return endpoint", :aggregate_failures do
      with_return_url("http://receiver.example/resume") do
        expect(described_class.redirect_url_for(params)).to be_nil
      end
      with_return_url("https://receiver.example") do
        expect(described_class.redirect_url_for(params)).to be_nil
      end
      with_return_url("https://receiver.example/resume?extra=1") do
        expect(described_class.redirect_url_for(params)).to be_nil
      end
      with_return_url("") do
        expect(described_class.redirect_url_for(params)).to be_nil
      end
    end

    it "rejects credentials, fragments, and malformed configuration", :aggregate_failures do
      ["https://user:pass@receiver.example/resume", "https://receiver.example/resume#fragment",
       "https://[", nil].each do |value|
        with_return_url(value) do
          expect(described_class.redirect_url_for(params)).to be_nil
        end
      end
    end

    it "rejects missing or malformed continuations", :aggregate_failures do
      with_return_url("https://receiver.example/resume") do
        expect(described_class.redirect_url_for("continuation" => "bad token&evil=1")).to be_nil
        expect(described_class.redirect_url_for("continuation" => "")).to be_nil
        expect(described_class.redirect_url_for(nil)).to be_nil
      end
    end
  end

  describe ".allowlisted_destination" do
    it "matches configured ports, including the default HTTPS port", :aggregate_failures do
      with_return_url("https://receiver.example/resume") do
        expect(described_class.allowlisted_destination("https://receiver.example:443/resume"))
          .to eq("https://receiver.example/resume")
      end
      with_return_url("https://receiver.example:444/resume") do
        expect(described_class.allowlisted_destination("https://receiver.example:444/resume"))
          .to eq("https://receiver.example:444/resume")
        expect(described_class.allowlisted_destination("https://receiver.example/resume")).to be_nil
      end
    end

    it "canonicalizes an exact allowlisted origin+path" do
      with_return_url("https://receiver.example/resume") do
        expect(described_class.allowlisted_destination("https://receiver.example/resume?x=1"))
          .to eq("https://receiver.example/resume")
      end
    end

    it "rejects wrong paths, wrong hosts, and relative values", :aggregate_failures do
      with_return_url("https://receiver.example/resume") do
        expect(described_class.allowlisted_destination("https://auth.mlh.test/web/auth/other")).to be_nil
        expect(described_class.allowlisted_destination("https://evil.example.com/resume")).to be_nil
        expect(described_class.allowlisted_destination("/resume")).to be_nil
        expect(described_class.allowlisted_destination("https://receiver.example/resume/extra")).to be_nil
        expect(described_class.allowlisted_destination("http://receiver.example/resume")).to be_nil
        expect(described_class.allowlisted_destination("https://receiver.example:444/resume")).to be_nil
        expect(described_class.allowlisted_destination("https://user@receiver.example/resume")).to be_nil
        expect(described_class.allowlisted_destination(nil)).to be_nil
      end
    end
  end
end
