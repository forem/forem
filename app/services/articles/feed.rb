module Articles
  class Feed
    attr_reader :stories

    def initialize(number_of_articles:, page:, tag: nil)
      @number_of_articles = number_of_articles
      @page = page
      @tag = tag
      @stories = published_articles_by_tag
    end

    def published_articles_by_tag
      articles = Article.published.limited_column_select.page(@page).per(@num_articles)
      articles = articles.cached_tagged_with(@tag) if @tag.present? # More efficient than tagged_with
      articles
    end

    def time_based_feed(timeframe:)
      stories.where("published_at > ?", Timeframer.new(timeframe).datetime).
        order("score DESC")
    end

    def latest_feed
      stories.order("published_at DESC").
        where("featured_number > ? AND score > ?", 1_449_999_999, -40)
    end

    def default_home_feed(user_signed_in: false)
      hot_stories = stories.
        where("score > ? OR featured = ?", 9, true).
        order("hotness_score DESC")
      featured_story = hot_stories.where.not(main_image: nil).first
      if user_signed_in
        offset = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9, 10, 11].sample # random offset, weighted more towards zero
        hot_stories = hot_stories.offset(offset)
      end
      new_stories = Article.published.
        where("published_at > ? AND score > ?", rand(2..6).hours.ago, -15).
        limited_column_select.order("published_at DESC").limit(rand(15..80))
      [featured_story, (hot_stories.to_a + new_stories.to_a)]
    end
  end
end
