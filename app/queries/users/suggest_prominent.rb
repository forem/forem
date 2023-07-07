module Users
  class SuggestProminent
    RETURNING = 50
    RECENT_WEEKS_TOP_PRODUCERS = 3
    USER_FOLLOWS_TAG_LIMIT = 5
    RECENT_TOP_PRODUCER_LIMIT = 80
    RECENT_COMMENTER_LIMIT = 30
    MINIMUM_COMMENTS = 4

    def self.call(user, attributes_to_select: [])
      new(user, attributes_to_select: attributes_to_select).suggest
    end

    def initialize(user, attributes_to_select: [])
      @user = user
      @attributes_to_select = attributes_to_select
    end

    def suggest
      users_to_follow = recently_published_articles_from_followed_tags if following_some_tags.any?
      users_to_follow ||= recent_commenters + recent_top_producers

      (users_to_follow - [user]).uniq.sample(RETURNING)
    end

    private

    attr_reader :user, :attributes_to_select

    def following_some_tags
      user.decorate.cached_followed_tag_names.sample(USER_FOLLOWS_TAG_LIMIT)
    end

    def tagged_article_user_ids(num_weeks)
      articles_from_followed_tags = Article.above_average
        .tagged_with(following_some_tags, any: true)
        .where(published_at: num_weeks.weeks.ago..)

      articles_from_followed_tags
        .pluck(:user_id)
        .each_with_object(Hash.new(0)) { |id, counts| counts[id] += 1 }
        .sort_by { |_id, count| count }
        .map(&:first)
    end

    def recently_published_articles_from_followed_tags(num_weeks = RECENT_WEEKS_TOP_PRODUCERS)
      users = user_finder.where(id: tagged_article_user_ids(num_weeks))
      relation_as_array(users, limit: RECENT_TOP_PRODUCER_LIMIT)
    end

    def recent_top_producers
      users = user_finder.above_average
      relation_as_array(users, limit: RETURNING)
    end

    def recent_commenters(num_comments = MINIMUM_COMMENTS, limit = RECENT_COMMENTER_LIMIT)
      commenters = user_finder.where(comments_count: num_comments..)
      relation_as_array(commenters, limit: limit)
    end

    def relation_as_array(relation, limit:)
      relation = relation.joins(:profile).select(attributes_to_select) if attributes_to_select.any?
      relation.order(updated_at: :desc).limit(limit).to_a
    end

    def user_finder
      @user_finder ||= User.includes(:profile).without_role(:suspended)
    end
  end
end
