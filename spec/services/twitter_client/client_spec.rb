require "rails_helper"

RSpec.describe TwitterClient::Client, :vcr, type: :service do
  let(:tweet_id) { "1018911886862057472" }

  describe ".status" do
    it "returns a status" do
      VCR.use_cassette("twitter_client_status") do
        tweet = described_class.status(tweet_id)
        expect(tweet.text).to be_present
      end
    end

    it "works properly when Settings::General is set" do
      VCR.use_cassette("twitter_client_status") do
        allow(Settings::Authentication).to receive(:twitter_key).and_return("test")
        tweet = described_class.status(tweet_id)
        expect(tweet.text).to be_present
      end
    end

    it "raises NotFound if the status does not exist" do
      VCR.use_cassette("twitter_client_status_not_found") do
        expect do
          described_class.status(0)
        end.to raise_error(TwitterClient::Errors::NotFound)
      end
    end
  end

  describe "handling underlying errors" do
    let(:client) { instance_double(Twitter::REST::Client) }

    before do
      allow(Twitter::REST::Client).to receive(:new).and_return(client)
    end

    it "matches defined errors by name" do
      allow(client).to receive(:status).and_raise(Twitter::Error::NotFound)

      expect { described_class.status(1) }.to raise_error(TwitterClient::Errors::NotFound)
    end

    it "matches client errors" do
      allow(client).to receive(:status).and_raise(Twitter::Error::BadRequest)

      expect { described_class.status(1) }.to raise_error(TwitterClient::Errors::ClientError)
    end

    it "matches server errors" do
      allow(client).to receive(:status).and_raise(Twitter::Error::ServiceUnavailable)

      expect { described_class.status(1) }.to raise_error(TwitterClient::Errors::ServerError)
    end

    it "defaults to a generic error" do
      allow(client).to receive(:status).and_raise(Twitter::Error)

      expect { described_class.status(1) }.to raise_error(TwitterClient::Errors::Error)
    end
  end
end
