module DisplayAds
  class FilteredAdsQuery
    def self.call(...)
      new(...).call
    end

    def initialize(display_ads:, area:, user_signed_in:, article_tags: [])
      @filtered_display_ads = display_ads
      @area = area
      @user_signed_in = user_signed_in
      @article_tags = article_tags
    end

    def call
      @filtered_display_ads = approved_and_published_ads
      @filtered_display_ads = placement_area_ads

      if @article_tags.any?
        @filtered_display_ads = tagged_post_comment_ads
      end

      if @article_tags.blank?
        @filtered_display_ads = untagged_post_comment_ads
      end

      @filtered_display_ads = if @user_signed_in
                                authenticated_ads(%w[all logged_in])
                              else
                                authenticated_ads(%w[all logged_out])
                              end

      @filtered_display_ads.order(success_rate: :desc)
      @filtered_display_ads = sample_ads
    end

    private

    def approved_and_published_ads
      @filtered_display_ads.approved_and_published
    end

    def placement_area_ads
      @filtered_display_ads.where(placement_area: @area)
    end

    def tagged_post_comment_ads
      display_ads_with_targeted_article_tags = @filtered_display_ads.cached_tagged_with_any(@article_tags)
      untagged_post_comment_ads.or(display_ads_with_targeted_article_tags)
    end

    def untagged_post_comment_ads
      @filtered_display_ads.where(cached_tag_list: "")
    end

    def authenticated_ads(display_auth_audience)
      @filtered_display_ads.where(display_to: display_auth_audience)
    end

    # Business Logic Context:
    # We are always showing more of the good stuff — but we are also always testing the system to give any a chance to
    # rise to the top. 1 out of every 8 times we show an ad (12.5%), it is totally random. This gives "not yet
    # evaluated" stuff a chance to get some engagement and start showing up more. If it doesn't get engagement, it
    # stays in this area.

    # Ads that get engagement have a higher "success rate", and among this category, we sample from the top 15 that
    # meet that criteria. Within those 15 top "success rates" likely to be clicked, there is a weighting towards the
    # top ranked outcome as well, and a steady decline over the next 15 — that's because it's not "Here are the top 15
    # pick one randomly", it is actually "Let's cut off the query at a random limit between 1 and 15 and sample from
    # that". So basically the "limit" logic will result in 15 sets, and then we sample randomly from there. The
    # "first ranked" ad will show up in all 15 sets, where as 15 will only show in 1 of the 15.
    def sample_ads
      if rand(8) == 1
        @filtered_display_ads.sample
      else
        @filtered_display_ads.limit(rand(1..15)).sample
      end
    end
  end
end
