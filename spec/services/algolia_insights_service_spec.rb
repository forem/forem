require "rails_helper"

RSpec.describe AlgoliaInsightsService do
  describe "#track_event" do
    let(:service) { described_class.new("app_id", "api_key") }
    let(:event_type) { "view" }
    let(:event_name) { "Article Viewed" }
    let(:user_id) { 1 }
    let(:object_id) { 123 }
    let(:index_name) { "Article_test" }

    it "tracks the event successfully" do
      stub_request(:post, "https://insights.algolia.io/1/events").to_return(status: 200, body: '{"message":"OK"}')

      result = service.track_event(event_type, event_name, user_id, object_id, index_name)
      expect(result).to be_success
    end

    it "returns nil without making a request when credentials are blank", :aggregate_failures do
      allow(Settings::General).to receive_messages(algolia_application_id: nil, algolia_api_key: nil)
      unconfigured_service = described_class.new
      allow(described_class).to receive(:post)

      expect(unconfigured_service.track_event(event_type, event_name, user_id, object_id, index_name)).to be_nil
      expect(described_class).not_to have_received(:post)
    end

    it "rescues transient network timeouts and SSL errors without reporting to error tracking", :aggregate_failures do
      [
        Net::ReadTimeout.new("Net::ReadTimeout with #<TCPSocket:(closed)>"),
        Net::OpenTimeout.new("execution expired"),
        OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0 state=error: unexpected eof while reading"),
      ].each do |network_error|
        allow(described_class).to receive(:post).and_raise(network_error)
        allow(Rails.logger).to receive(:warn)
        allow(Rails.error).to receive(:report)

        result = service.track_event(event_type, event_name, user_id, object_id, index_name)

        expect(result).to be_nil
        expected_pattern = /AlgoliaInsightsService network error: #{Regexp.escape(network_error.class.name)}/
        expect(Rails.logger).to have_received(:warn).with(expected_pattern)
        expect(Rails.error).not_to have_received(:report)
      end
    end

    it "rescues unexpected non-network errors, logs a warning, and reports to Rails.error", :aggregate_failures do
      unexpected_error = StandardError.new("unexpected serialization bug")
      allow(described_class).to receive(:post).and_raise(unexpected_error)
      allow(Rails.logger).to receive(:warn)
      allow(Rails.error).to receive(:report)

      result = service.track_event(event_type, event_name, user_id, object_id, index_name)

      expect(result).to be_nil
      expected_pattern = /AlgoliaInsightsService error: StandardError: unexpected serialization bug/
      expect(Rails.logger).to have_received(:warn).with(expected_pattern)
      expect(Rails.error).to have_received(:report).with(unexpected_error)
    end
  end
end
