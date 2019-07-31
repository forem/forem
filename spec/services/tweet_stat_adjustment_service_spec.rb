require "rails_helper"

RSpec.describe TweetStatAdjustmentService do
  let(:travel_time) { TweetStatAdjustmentService::ADVANCE_IN_HOURS }

  def build_article(*args)
    create(:article, *args)
  end

  def travel(distance, &block)
    Timecop.travel(distance)
    value = yield block
    Timecop.return

    value
  end

  def freeze(&block)
    Timecop.freeze
    yield block
    Timecop.return
  end

  describe "validation of eligible tweet nodes", :vcr do
    context "when article has twitter liquid tag(s)" do
      let(:article) { build_article(with_tweet_tag: true) }

      it "is valid when node is an instance of TweetTag Class" do
        VCR.use_cassette("twitter_gem") do
          # Uses Timecop to modify the created_at attribute of the Tweet
          service = travel(travel_time.hours.ago) do
            described_class.new(article.body_markdown.to_s)
          end

          expect(service.tweet_nodes.map(&:class)).to eq([TweetTag])
        end
      end

      it "is invalid when tweet object is not old enough" do
        VCR.use_cassette("twitter_gem") do
          service = described_class.new(article.body_markdown.to_s)

          expect(service.tweet_nodes.map(&:class)).to eq([])
        end
      end
    end

    context "when article is without twitter liquid tag(s)" do
      let(:article) { build_article }

      it "is invalid" do
        service = described_class.new(article.body_markdown.to_s)

        expect(service.tweet_nodes.map(&:class)).to eq([])
      end
    end
  end

  describe "tweet adjustment", :vcr do
    let(:article) { build_article(with_tweet_tag: true) }

    it "makes update on Twitter last_fetched_at attribute" do
      VCR.use_cassette("twitter_gem", allow_playback_repeats: true) do
        # Uses Timecop to modify the created_at attribute of the Tweet
        service = travel(travel_time.hours.ago) do
          described_class.new(article.body_markdown.to_s)
        end

        nodes = service.tweet_nodes

        freeze do
          service.call
          expect(nodes.sample.tweet.last_fetched_at).to eq(Time.zone.now)
        end
      end
    end
  end
end
