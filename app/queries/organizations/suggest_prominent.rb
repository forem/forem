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
      Article.published.cached_tagged_with_any(tags_to_consider).where.not(organization_id: nil)
        .order("hotness_score DESC").limit(MAX * 2).pluck(:organization_id)
    end
  end
end
