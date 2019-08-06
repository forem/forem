module TweetTags
  class RefreshStats
    ADVANCE_IN_HOURS = 8

    def initialize(markdown_content)
      @content = markdown_content
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      tweet_nodes.each do |node|
        adjust(node.tweet)
      end
    end

    private

    def tweet_nodes
      parser.liquid_nodes.select { |node| eligible?(node) }
    end

    def parser
      @parser ||= MarkdownParser.new(@content)
    end

    def eligible?(node)
      tweet_tag_class?(node) && enough_old?(node)
    end

    def tweet_tag_class?(node)
      node.class.eql?(TweetTag)
    end

    def enough_old?(node)
      node.tweet.last_fetched_at.advance(hours: ADVANCE_IN_HOURS).past?
    end

    def adjust(tweet)
      fresh_tweet = TwitterBot.fetch(tweet.twitter_id_code)

      tweet.favorite_count = fresh_tweet.favorite_count
      tweet.retweet_count = fresh_tweet.retweet_count
      tweet.twitter_user_following_count = fresh_tweet.user.friends_count
      tweet.twitter_user_followers_count = fresh_tweet.user.followers_count
      tweet.last_fetched_at = Time.zone.now
      tweet.save!
    end
  end
end
