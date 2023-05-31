module Organizations
  class SuggestProminent
    class_attribute :average_score
    RECENTLY = 3

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
      article_scope = articles_from_followed_tags || Article
      recently_published = article_scope.where(published_at: self.class.recently_published_at)

      organization_ids = above_average_articles_with_organization(recently_published)
        .select("DISTINCT ON (articles.organization_id) *")
        .limit(5)
        .pluck(:organization_id)

      Organization.where(id: organization_ids)
    end

    private

    attr_reader :current_user

    def above_average_articles_with_organization(scope)
      scope.above_average.where.not(organization_id: nil)
    end

    def articles_from_followed_tags(scope = Article)
      tags = current_user.currently_following_tags.pluck(:name).join(",")
      return if tags.blank?

      scope.tagged_with(tags, any: true)
    end
  end
end
