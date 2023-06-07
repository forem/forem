module Organizations
  class SuggestProminent
    class_attribute :average_score
    class_attribute :article_finder, default: Article

    RECENTLY = 3
    MAX = 5

    def self.recently_published_at
      (RECENTLY.weeks.ago..)
    end

    def self.call(...)
      new(...).suggest
    end

    def initialize(current_user)
      @current_user = current_user
    end

    def suggest
      scope = article_finder.merge(above_average_articles)
        .merge(organization_affiliated_articles)
        .merge(recently_published_articles)
      from_followed = scope.merge(articles_from_followed_tags)

      # Prefer orgs from followed tags, fill from the larger scope if needed
      # Postgres doesn't like when DISTINCT doesn't line up with SELECT,
      # which means doing this in the DB would require a sub-select.
      # UNION would also be an option, except that UNION does not guarantee
      # result order. If we want followed-tags-orgs to come earlier in the
      # list, this seems to be our best option.
      unique_org_ids = unique_org_ids(from_followed)
      if unique_org_ids.size <= MAX
        additional_org_ids = unique_org_ids(scope)[..(MAX - unique_org_ids.size)]
        unique_org_ids += additional_org_ids
      end

      Organization.where(id: unique_org_ids).limit(MAX)
    end

    private

    attr_reader :current_user

    def above_average_articles
      article_finder.above_average
    end

    def organization_affiliated_articles
      article_finder.where.not(organization_id: nil)
    end

    def recently_published_articles
      article_finder.where(published_at: self.class.recently_published_at)
    end

    def articles_from_followed_tags
      tags = current_user.currently_following_tags.pluck(:name).join(",")
      return article_finder.none if tags.blank?

      article_finder.tagged_with(tags, any: true)
    end

    def unique_org_ids(scoped_query)
      scoped_query.pluck(:organization_id).uniq
    end
  end
end
