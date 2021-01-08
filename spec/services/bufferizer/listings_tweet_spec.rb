require "rails_helper"

RSpec.describe Bufferizer::ListingsTweet, type: :service do
  describe "#call" do
    let(:user) { create(:user) }
    let(:listing) { create(:listing, user_id: user.id) }

    context "when listing is nil" do
      it "doesn't raise an error" do
        tweet = "test tweet"
        expect { described_class.call(nil, tweet) }.not_to raise_error
      end
    end

    context "when tweet is nil" do
      it "doesn't raise an error" do
        expect { described_class.call(listing, nil) }.not_to raise_error
      end
    end

    it "sends to buffer listings" do
      text = "test listing"
      described_class.call(listing, text)
      expect(listing.last_buffered).not_to be(nil)
    end
  end
end
