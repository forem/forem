class UserFollowSuggester

  attr_accessor :user
  def initialize(user)
    @user = user
  end

  def suggestions
    user_ids = tagged_article_user_ids
    if user.decorate.cached_followed_tag_names.any?
      group_1 = User.where(id: user_ids).
        order("reputation_modifier DESC").offset(rand(0..offset_number)).limit(15).to_a
      group_2 = User.where(id: user_ids).
        order("twitter_following_count DESC").offset(rand(0..offset_number)).limit(15).to_a
      group_3 = User.where(id: user_ids).
        order("articles_count DESC").limit(20).offset(rand(0..offset_number)).to_a
      group_4 = User.where(id: user_ids).
        order("comments_count DESC").limit(25).offset(rand(0..offset_number)).to_a
      group_5 = User.order("reputation_modifier DESC").offset(rand(0..offset_number)).limit(15).to_a
      group_6 = User.order("comments_count DESC").offset(rand(0..offset_number)).limit(15).to_a
      group_7 = User.tagged_with(user.decorate.cached_followed_tag_names, any: true).limit(15).to_a

      users = ((group_1 + group_2 + group_3 + group_4 + group_5 + group_6 - [user]).
        shuffle.first(50) + group_7).uniq
    else
      group_1 = User.order("reputation_modifier DESC").offset(rand(0..offset_number)).limit(100).to_a
      group_2 = User.where("articles_count > ?", 5).
        order("twitter_following_count DESC").offset(rand(0..offset_number)).limit(100).to_a
      group_3 = User.order("comments_count DESC").offset(rand(0..offset_number)).limit(100).to_a
      users = (group_1 + group_2 + group_3 - [user]).
        uniq.shuffle.first(50)
    end
    users
  end

  def sidebar_suggestions(given_tag)
    user_ids = Article.tagged_with([given_tag], any: true).
      where("published = ? AND positive_reactions_count > ? AND published_at > ? AND user_id != ?",
        true, 15, 7.months.ago, user.id).pluck(:user_id)
    user.following_by_type("User").where.not(id: user_ids).
      order("reputation_modifier DESC").limit(3).to_a
  end

  def tagged_article_user_ids
    Article.
      tagged_with(user.decorate.cached_followed_tag_names, any: true).
      where(published: true).
      where("positive_reactions_count > ? AND published_at > ?", article, 7.months.ago).
      pluck(:user_id).
      each_with_object(Hash.new(0)) { |value, counts| counts[value] += 1 }.
      sort_by { |_key, value| value }.
      map { |arr| arr[0] }
  end

  def offset_number
    Rails.env.production? ? 250 : 0
  end

  def article
    Rails.env.production? ? 15 : 0
  end
end
