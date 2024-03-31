module Users
  class SuggestProminent
    RETURNING = 50

    def self.call(user, attributes_to_select: [])
      new(user, attributes_to_select: attributes_to_select).suggest
    end

    def initialize(user, attributes_to_select: [])
      @user = user
      @attributes_to_select = attributes_to_select
    end

    def suggest
      User.joins(:profile).without_role(:suspended).where(id: fetch_and_pluck_user_ids.uniq)
        .limit(RETURNING).select(attributes_to_select)
    end

    private

    attr_reader :user, :attributes_to_select

    def tags_to_consider
      user.decorate.cached_followed_tag_names
    end

    def fetch_and_pluck_user_ids
      filtered_articles = if tags_to_consider.any?
                            Article.published.cached_tagged_with_any(tags_to_consider)
                          else
                            Article.published.featured
                          end
      user_ids = filtered_articles.order("hotness_score DESC").limit(RETURNING * 2).pluck(:user_id) - [user.id]
      if user_ids.size > (RETURNING / 2)
        user_ids.sample(RETURNING)
      else
        # This is a fallback in case we don't have enough users to return
        # Will generally not be called — but maybe for brand new forems
        User.order("score DESC").limit(RETURNING * 2).ids - [user.id]
      end
    end
  end
end
