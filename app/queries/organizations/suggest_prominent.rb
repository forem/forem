module Organizations
  class SuggestProminent
    MAX = 5

    def self.call(...)
      new(...).suggest
    end

    def initialize(user)
      @user = user
    end

    def suggest
      return [] if tags_to_consider.empty?

      org_ids = fetch_and_pluck_org_ids
      Organization.where(id: org_ids.uniq).order(Arel.sql("RANDOM()")).limit(MAX)
    end

    private

    attr_reader :user

    def tags_to_consider
      user.decorate.cached_followed_tag_names
    end

    def fetch_and_pluck_org_ids
      lookback_setting = Settings::UserExperience.feed_lookback_days.to_i
      lookback = lookback_setting.positive? ? lookback_setting.days.ago : 2.weeks.ago
      Article.published.from_subforem.cached_tagged_with_any(tags_to_consider).where.not(organization_id: nil)
        .where("published_at > ?", lookback).where("score > ?", Settings::UserExperience.index_minimum_score * 2)
        .order("score DESC").limit(MAX * 2).pluck(:organization_id)
    end
  end
end
