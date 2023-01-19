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
      relation = @display_ads.approved_and_published.where(placement_area: @area).order(success_rate: :desc)

      if @article_tags.any?
        display_ads_with_no_tags = relation.where(cached_tag_list: "")
        display_ads_with_targeted_article_tags = relation.cached_tagged_with_any(@article_tags)

        relation = display_ads_with_no_tags.or(display_ads_with_targeted_article_tags)
      end

      if @article_tags.blank?
        relation = relation.where(cached_tag_list: "")
      end

      relation = if @user_signed_in
                   relation.where(display_to: %w[all logged_in])
                 else
                   relation.where(display_to: %w[all logged_out])
                 end

      relation.order(success_rate: :desc)

      if rand(8) == 1
        relation.sample
      else
        relation.limit(rand(1..15)).sample
      end
    end
  end
end
