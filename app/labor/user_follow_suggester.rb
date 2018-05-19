class UserFollowSuggester

  attr_accessor :user
  def initialize(user)
    @user = user
  end

  def suggestions
    if user.decorate.cached_followed_tag_names.any?
      users = ((recent_producers(1) + recent_producers(4) + recent_commenters - [user]).
        shuffle.first(55) + tagged_producers).uniq
    else
      users = (recent_commenters(4, 30) + recent_top_producers - [user]).
        uniq.shuffle.first(50)
    end
    users
  end

  def sidebar_suggestions(given_tag)
    Rails.cache.fetch("tag-#{given_tag}_user-#{user.id}-#{user.last_followed_at}/tag-follow-sugggestions", expires_in: 120.hours) do
      reaction_count = Rails.env.production? ? 25 : 0
      user_ids = Article.tagged_with([given_tag], any: true).
        where(
          "published = ? AND positive_reactions_count > ? AND published_at > ? AND user_id != ?",
          true, reaction_count, 4.months.ago, user.id
        ).where.not(user_id: user.following_by_type("User").pluck(:id)).pluck(:user_id)
      group_one = User.select(:id, :name, :username, :profile_image).where(id: user_ids).
        order("reputation_modifier DESC").limit(20).to_a
      group_two = User.select(:id, :name, :username, :profile_image).where(id: user_ids).
        order("RANDOM()").limit(20).to_a
      (group_one + group_two).uniq
    end
  end

  def tagged_article_user_ids(num_weeks=1)
    Article.
      tagged_with(user.decorate.cached_followed_tag_names, any: true).
      where(published: true).
      where("positive_reactions_count > ? AND published_at > ?",
        article_reaction_count, num_weeks.weeks.ago).
      pluck(:user_id).
      each_with_object(Hash.new(0)) { |value, counts| counts[value] += 1 }.
      sort_by { |_key, value| value }.
      map { |arr| arr[0] }
  end

  def recent_producers(num_weeks=1)
    User.where(id: tagged_article_user_ids(num_weeks)).order("updated_at DESC").limit(50).to_a
  end

  def recent_top_producers
    User.where("articles_count > ? AND comments_count > ?",
      established_user_article_count, established_user_comment_count).
      order("updated_at DESC").limit(50).to_a
  end

  def recent_commenters(num_coumments=2,limit=8)
    User.where("comments_count > ?", num_coumments).order("updated_at DESC").limit(limit).to_a
  end

  def tagged_producers
    User.tagged_with(user.decorate.cached_followed_tag_names, any: true).limit(15).to_a
  end

  def established_user_article_count
    Rails.env.production? ? 4 : -1
  end

  def established_user_comment_count
    Rails.env.production? ? 4 : -1
  end

  def article_reaction_count
    Rails.env.production? ? 14 : -1
  end
end
