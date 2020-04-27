module Articles
  class Score
    attr_reader :article,
                :user,
                :tag_weight,
                :randomness,
                :comment_weight,
                :experience_level_weight

    def initialize(options = {})
      @article = options[:article]
      @user = options[:user]
      @tag_weight = options[:tag_weight]
      @randomness = options[:randomness]
      @comment_weight = options[:comment_weight]
      @experience_level_weight = options[:experience_level_weight]
    end

    def score_single_article
      article_points = 0
      article_points += score_followed_user
      article_points += score_followed_organization
      article_points += score_followed_tags
      article_points += score_randomness
      article_points += score_language
      article_points += score_experience_level
      article_points += score_comments
      article_points
    end

    def score_followed_user
      user_following_users_ids.include?(article.user_id) ? 1 : 0
    end

    def user_following_users_ids
      @user_following_users_ids ||= user.cached_following_users_ids || []
    end

    def score_followed_tags
      return 0 unless user

      article_tags = article.decorate.cached_tag_list_array
      user_followed_tags.sum do |tag|
        article_tags.include?(tag.name) ? tag.points * tag_weight : 0
      end
    end

    def user_followed_tags
      @user_followed_tags ||= (user.decorate.cached_followed_tags || [])
    end

    def score_followed_organization
      user_following_org_ids.include?(article.organization_id) ? 1 : 0
    end

    def score_randomness
      rand(3) * randomness
    end

    def score_language
      user.preferred_languages_array&.include?(article.language || "en") ? 1 : -15
    end

    def score_experience_level
      - (((article.experience_level_rating - (user.experience_level || 5)).abs / 2) * experience_level_weight)
    end

    def score_comments
      article.comments_count * comment_weight
    end

    def user_following_org_ids
      @user_following_org_ids ||= (user&.cached_following_organizations_ids || [])
    end
  end
end
