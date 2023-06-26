require "rails_helper"

RSpec.describe TweetTag, type: :liquid_tag do
  describe "#id" do
    let(:valid_id)      { "1671839966572290048" }
    let(:invalid_id)    { "blahblahblahbl" }

    def generate_tweet_tag(id)
      Liquid::Template.register_tag("tweet", TweetTag)
      Liquid::Template.parse("{% tweet #{id} %}")
    end

    it "checks that the tag is properly parsed" do
      valid_id = "1671839966572290048"
      liquid = generate_tweet_tag(valid_id)

      # rubocop:disable Style/StringLiterals
      expect(liquid.render).to include('<blockquote')
        .and include('class="twitter-tweet"')
        .and include("<a href=\"https://twitter.com/tweet/status/#{valid_id}\">Fetching tweet</a>")
        .and include('<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>')
      # rubocop:enable Style/StringLiterals
    end

    it "rejects invalid ids" do
      expect { generate_tweet_tag(invalid_id) }.to raise_error(StandardError)
    end

    it "accepts a valid id" do
      expect { generate_tweet_tag(valid_id) }.not_to raise_error
    end
  end
end
