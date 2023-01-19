module DisplayAds
  class SampleRelevantAds
    def self.call(display_ads, area, user_signed_in, article_tags)
      new(display_ads, area, user_signed_in, article_tags).call
    end

    def initialize(display_ads, area, user_signed_in, article_tags)
      @display_ads = display_ads
      @area = area
      @user_signed_in = user_signed_in
      @article_tags = article_tags
    end

    def call
      relation = approved_and_published_ads

      if @article_tags.any?
        relation = tagged_post_comment_ads(relation)
      end

      if @article_tags.blank?
        relation = display_ads_with_no_tags(relation)
      end

      relation = authenticated_ads(relation)
      relation.order(success_rate: :desc)

      sample_ads(relation)
    end

    private

    def approved_and_published_ads
      @display_ads.approved_and_published.where(placement_area: @area).order(success_rate: :desc)
    end

    def tagged_post_comment_ads(relation)
      display_ads_with_no_tags = display_ads_with_no_tags(relation)
      display_ads_with_targeted_article_tags = relation.cached_tagged_with_any(@article_tags)

      display_ads_with_no_tags.or(display_ads_with_targeted_article_tags)
    end

    def display_ads_with_no_tags(relation)
      relation.where(cached_tag_list: "")
    end

    def authenticated_ads(relation)
      if @user_signed_in
        relation.where(display_to: %w[all logged_in])
      else
        relation.where(display_to: %w[all logged_out])
      end
    end

    # We are always showing more of the good stuff — but we are also always testing the system to give any a chance to
    # rise to the top. 1 out of every 8 times we show an ad (12.5%), it is totally random. This gives "not yet
    # evaluated" stuff a chance to get some engagement and start showing up more. If it doesn't get engagement, it
    # stays in this area.

    # Ads that get engagemen have a higher "success rate", and among this category, we sample from the top 15 that
    # meet that criteria. Within those 15 top "success rates" likely to be clicked, there is a weighting towards the
    # top ranked outcome as well, and a steady decline over the next 15 — that's because it's not "Here are the top 15
    # pick one randomly", it is actually "Let's cut off the query at a random limit between 1 and 15 and sample from
    # that". So basically the "limit" logic will result in 15 sets, and then we sample randomly from there. The
    # "first ranked" ad will show up in all 15 sets, where as 15 will only show in 1 of the 15.
    def sample_ads(relation)
      if rand(8) == 1
        relation.sample
      else
        relation.limit(rand(1..15)).sample
      end
    end
  end
end
