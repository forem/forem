require "rails_helper"

RSpec.describe TwitterBot do
  let(:client) { double }
  let(:twitter_id) { "1018911886862057472" }

  it "returns an extended tweet", :vcr do
    VCR.use_cassette("twitter_gem") do
      expect(described_class.fetch(twitter_id).class).to eq(Twitter::Tweet)
    end
  end

  it "returns normal tweet", :vcr do
    VCR.use_cassette("tweet") do
      expect(described_class.get(twitter_id).class).to eq(Twitter::Tweet)
    end
  end

  context "when client raise error(s)" do
    it "returns nil object as tweet" do
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:status).with(twitter_id, tweet_mode: "extended").and_raise(Twitter::Error)

      expect(described_class.fetch(twitter_id)).to be_nil
    end
  end
end
