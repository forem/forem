require "rails_helper"

RSpec.describe TwitterClient::Client, type: :service, vcr: true do
  let(:tweet_id) { "1018911886862057472" }

  describe ".status" do
    it "returns a status" do
      VCR.use_cassette("twitter_client_status") do
        tweet = described_class.status(tweet_id)
        expect(tweet.text).to be_present
      end
    end

    it "works properly when SiteConfig is set" do
      VCR.use_cassette("twitter_client_status") do
        allow(SiteConfig).to receive(:twitter_key).and_return("test")
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
end
