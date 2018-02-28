require "rails_helper"

RSpec.describe TweetTag, type: :liquid_template do
  let(:twitter_id)  { "783472379167113216" }

  setup             { Liquid::Template.register_tag("tweet", TweetTag) }

  def generate_tweet_liquid_tag(id)
    Liquid::Template.parse("{% tweet #{id} %}")
  end

  it "accepts valid tweet id" do
    liquid = generate_tweet_liquid_tag(twitter_id)
    dir = File.join(File.dirname(__FILE__), "../support/fixtures/tweet_1.json")
    actual_response = JSON.parse(File.read(dir))
    expect(liquid.root.nodelist[0].tweet.text).to eq(actual_response["text"])
  end

  context "when given invalid id" do
    it "rejects it (normal invalid id)" do
      expect do
        generate_tweet_liquid_tag("really_long_invalid_id")
      end.to raise_error(StandardError)
    end

    it "rejects it (xss content)" do
      expect do
        generate_tweet_liquid_tag("834439977220112384\" onmouseover=\"alert(document.domain)\"")
      end.to raise_error(StandardError)
    end
  end
end
