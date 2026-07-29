require "rails_helper"

RSpec.describe Mlh::ApiClient, type: :service do
  let(:access_token) { "mlh-access-token" }
  let(:path) { "/v4/users/me" }
  let(:url) { "https://api.mlh.com/v4/users/me" }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("MLH_API_BASE_URL").and_return(nil)
  end

  describe "#get" do
    it "returns the parsed body on success" do
      stub_request(:get, url)
        .to_return(status: 200, body: { "id" => "abc" }.to_json,
                   headers: { "Content-Type" => "application/json" })

      expect(described_class.new(access_token).get(path)).to eq("id" => "abc")
    end

    it "authenticates with the access token" do
      stub_request(:get, url)
        .with(headers: { "Authorization" => "Bearer #{access_token}" })
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      described_class.new(access_token).get(path)

      expect(WebMock).to have_requested(:get, url)
        .with(headers: { "Authorization" => "Bearer #{access_token}" })
    end

    it "raises ArgumentError without a token" do
      expect { described_class.new(nil).get(path) }.to raise_error(ArgumentError)

      expect(WebMock).not_to have_requested(:get, url)
    end

    it "raises a terminal ClientError when the token is rejected" do
      stub_request(:get, url).to_return(status: 401, body: "")

      expect { described_class.new(access_token).get(path) }
        .to raise_error(Mlh::ApiClient::ClientError)
    end

    it "raises a RecoverableError on a 5xx" do
      stub_request(:get, url).to_return(status: 500, body: "")

      expect { described_class.new(access_token).get(path) }
        .to raise_error(Mlh::ApiClient::RecoverableError)
    end

    it "raises a RecoverableError on a timeout" do
      stub_request(:get, url).to_timeout

      expect { described_class.new(access_token).get(path) }
        .to raise_error(Mlh::ApiClient::RecoverableError)
    end

    [408, 429].each do |status|
      it "raises a RecoverableError on a #{status}" do
        stub_request(:get, url).to_return(status: status, body: "")

        expect { described_class.new(access_token).get(path) }
          .to raise_error(Mlh::ApiClient::RecoverableError)
      end
    end

    it "raises a terminal ClientError on a 404" do
      stub_request(:get, url).to_return(status: 404, body: "")

      expect { described_class.new(access_token).get(path) }
        .to raise_error(Mlh::ApiClient::ClientError)
    end

    it "raises a ClientError when the response is not JSON" do
      stub_request(:get, url).to_return(status: 200, body: "<html>nope</html>")

      expect { described_class.new(access_token).get(path) }
        .to raise_error(Mlh::ApiClient::ClientError)
    end

    describe "terminal failure handing" do
      before { allow(Rails.logger).to receive(:error) }

      it "logs when token is rejected" do
        stub_request(:get, url).to_return(status: 401, body: "")

        suppress(Mlh::ApiClient::Error) { described_class.new(access_token).get(path) }

        expect(Rails.logger).to have_received(:error).with(/Mlh::ApiClient.*HTTP 401/)
      end

      it "logs an unparseable body" do
        stub_request(:get, url).to_return(status: 200, body: "<html>nope</html>")

        suppress(Mlh::ApiClient::Error) { described_class.new(access_token).get(path) }

        expect(Rails.logger).to have_received(:error).with(/Mlh::ApiClient.*unparseable/)
      end

      it "does not log the access token" do
        stub_request(:get, url).to_return(status: 401, body: "")

        suppress(Mlh::ApiClient::Error) { described_class.new(access_token).get(path) }

        expect(Rails.logger).not_to have_received(:error).with(/#{access_token}/)
      end
    end

    it "targets a local MLH Core when MLH_API_BASE_URL is set" do
      local_url = "http://host.docker.internal:3001/v4/users/me"
      allow(ApplicationConfig).to receive(:[]).with("MLH_API_BASE_URL")
        .and_return("http://host.docker.internal:3001")
      stub_request(:get, local_url).to_return(status: 200, body: "{}",
                                              headers: { "Content-Type" => "application/json" })

      described_class.new(access_token).get(path)

      expect(WebMock).to have_requested(:get, local_url)
    end
  end
end
