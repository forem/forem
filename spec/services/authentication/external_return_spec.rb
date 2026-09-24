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

  describe ".capture" do
    it "keeps only a well-formed continuation as opaque context", :aggregate_failures do
      expect(described_class.capture(params)).to eq("continuation" => "cont-token_1")
      expect(described_class.capture(params.merge("state" => "navbar"))).to eq("continuation" => "cont-token_1")
    end

    it "returns nil for missing or malformed continuations", :aggregate_failures do
      expect(described_class.capture("continuation" => "bad token&evil=1")).to be_nil
      expect(described_class.capture("continuation" => "")).to be_nil
      expect(described_class.capture({})).to be_nil
      expect(described_class.capture(nil)).to be_nil
    end
  end

  describe ".resolve" do
    it "builds the redirect from the configured endpoint, carrying the continuation verbatim" do
      with_return_url("https://receiver.example/resume") do
        url = described_class.resolve(described_class.capture(params))
        expect(url).to eq("https://receiver.example/resume?continuation=cont-token_1")
      end
    end

    it "keeps a non-default port and drops the default one", :aggregate_failures do
      with_return_url("https://receiver.example:444/resume") do
        expect(described_class.resolve(params)).to eq("https://receiver.example:444/resume?continuation=cont-token_1")
      end
      with_return_url("https://receiver.example:443/resume") do
        expect(described_class.resolve(params)).to eq("https://receiver.example/resume?continuation=cont-token_1")
      end
    end

    it "returns nil for a missing or tampered context", :aggregate_failures do
      with_return_url("https://receiver.example/resume") do
        expect(described_class.resolve(nil)).to be_nil
        expect(described_class.resolve({})).to be_nil
        expect(described_class.resolve("continuation" => "bad token&evil=1")).to be_nil
      end
    end

    it "requires a configured HTTPS endpoint with a path and nothing else", :aggregate_failures do
      ["http://receiver.example/resume", "https://receiver.example", "https://receiver.example/resume?extra=1",
       "https://user:pass@receiver.example/resume", "https://receiver.example/resume#fragment",
       "https://[", "", nil].each do |value|
        with_return_url(value) do
          expect(described_class.resolve(params)).to be_nil
        end
      end
    end
  end

  describe "feature gate" do
    [nil, "", "false", "1", "TRUE"].each do |value|
      it "resolves nothing when the flag is #{value.inspect}" do
        ENV["FOREM_EXTERNAL_RETURN_ENABLED"] = value
        with_return_url("https://receiver.example/resume") do
          expect(described_class.redirect_url_for(params)).to be_nil
        end
      end
    end
  end
end
