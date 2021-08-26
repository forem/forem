module Users
  class SuggestRecent
    def self.call(user, attributes_to_select: [])
      new(user, attributes_to_select: attributes_to_select).suggest
    end

    def initialize(user, attributes_to_select: [])
      @user = user
      @cached_followed_tag_names = user.decorate.cached_followed_tag_names
      @attributes_to_select = attributes_to_select
    end

    def suggest
      if cached_followed_tag_names.any?
        (recent_producers(3) - [user]).sample(50).uniq
      else
        (recent_commenters(4, 30) + recent_top_producers - [user]).uniq.sample(50)
      end
    end

    private

    attr_reader :user, :attributes_to_select, :cached_followed_tag_names

    def tagged_article_user_ids(num_weeks = 1)
      Article.published
        .tagged_with(cached_followed_tag_names.sample(5), any: true)
        .where(score: article_score_average.., published_at: num_weeks.weeks.ago..)
        .pluck(:user_id)
        .each_with_object(Hash.new(0)) { |value, counts| counts[value] += 1 }
        .sort_by { |_key, value| value }
        .map(&:first)
    end

    def recent_producers(num_weeks = 1)
      relation_as_array(
        user_relation.where(id: tagged_article_user_ids(num_weeks)),
        limit: 80,
      )
    end

    def recent_top_producers
      relation = user_relation.where(
        articles_count: established_user_article_count..,
        comments_count: established_user_comment_count..,
      )
      relation_as_array(relation, limit: 50)
    end

    def recent_commenters(num_comments = 2, limit = 8)
      relation_as_array(user_relation.where(comments_count: num_comments + 1..), limit: limit)
    end

    def relation_as_array(relation, limit:)
      relation = relation.joins(:profile).select(attributes_to_select) if attributes_to_select.any?
      relation.order(updated_at: :desc).limit(limit).to_a
    end

    def established_user_article_count
      Rails.cache.fetch("established_user_article_count", expires_in: 1.day) do
        user_relation.where(articles_count: 1..).average(:articles_count) || User.average(:articles_count)
      end
    end

    def established_user_comment_count
      Rails.cache.fetch("established_user_comment_count", expires_in: 1.day) do
        user_relation.where(comments_count: 1..).average(:comments_count) || User.average(:comments_count)
      end
    end

    def article_score_average
      Rails.cache.fetch("article_score_average", expires_in: 1.day) do
        Article.where(score: 0..).average(:score) || Article.average(:score)
      end
    end

    def user_relation
      User.includes(:profile)
    end
  end
end
