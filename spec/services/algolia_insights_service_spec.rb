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

    it "rescues network errors, logs a warning, and notifies Honeybadger" do
      # Simulate a network error (like the one reported: OpenSSL::SSL::SSLError)
      allow(AlgoliaInsightsService).to receive(:post).and_raise(OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0 state=error: unexpected eof while reading"))

      expect(Rails.logger).to receive(:warn).with(/AlgoliaInsightsService network error/)
      expect(Honeybadger).to receive(:notify).with(instance_of(OpenSSL::SSL::SSLError))

      # The method should gracefully return nil without bubbling the exception
      result = service.track_event(event_type, event_name, user_id, object_id, index_name)
      expect(result).to be_nil
    end
  end
end
