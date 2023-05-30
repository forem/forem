module Organizations
  class SuggestProminent
    class_attribute :average_score

    def self.call(...)
      new(...).suggest
    end

    def initialize(current_user)
      @current_user = current_user
    end

    def suggest
      article_scope = articles_from_followed_tags || Article

      organization_ids = above_average_articles_with_organization(article_scope)
        .pluck(:organization_id)

      Organization.where(id: organization_ids)
    end

    private
    attr_reader :current_user

    def above_average_articles_with_organization(scope)
      scope.above_average.where("organization_id IS NOT NULL")
    end


    def articles_from_followed_tags(scope=Article)
      tags = current_user.currently_following_tags.pluck(:name).join(',')
      return if tags.blank?
      scope.tagged_with(tags, any: true)
    end
  end
end
