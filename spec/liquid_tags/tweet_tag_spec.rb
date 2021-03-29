require "rails_helper"

RSpec.describe TweetTag, type: :liquid_tag do
  let(:twitter_id) { "1018911886862057472" }
  let(:handle) { "thepracticaldev" }
  let(:name) { "DEV Community" }
  let(:body) { "When GitHub goes down" }

  setup { Liquid::Template.register_tag("tweet", described_class) }

  def generate_tweet_liquid_tag(id)
    Liquid::Template.parse("{% tweet #{id} %}")
  end

  it "accepts valid tweet id", :vcr do
    VCR.use_cassette("twitter_client_status_extended") do
      liquid = generate_tweet_liquid_tag(twitter_id)
      body = liquid.render

      expect(body).to include(handle)
      expect(body).to include(name)
      expect(body).to include(body)
    end
  end

  it "render properly", :vcr do
    VCR.use_cassette("twitter_client_status_extended") do
      Time.use_zone("Asia/Tokyo") do
        rendered = generate_tweet_liquid_tag(twitter_id).render

        expect(rendered).to include('<blockquote class="ltag__twitter-tweet"')
        expect(rendered).to include('<div class="ltag__twitter-tweet__main"')
        expect(rendered).to include('<div class="ltag__twitter-tweet__actions">')
      end
    end
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
