class UserFollowSuggester

  attr_accessor :user
  def initialize(user)
    @user = user
  end

  def suggestions
    user_ids = tagged_article_user_ids
    if user.decorate.cached_followed_tag_names.any?
      group_1 = User.where(id: user_ids).
        order("reputation_modifier DESC").limit(25).to_a
      group_2 = User.where(id: user_ids).
        order("twitter_following_count DESC").limit(25).to_a
      group_3 = User.where(id: user_ids).
        order("articles_count DESC").limit(25).to_a
      group_4 = User.order("reputation_modifier DESC").limit(30).to_a
      group_5 = User.order("comments_count DESC").limit(25).to_a
      users = (group_1 + group_2 + group_3 + group_4 + group_5 - [user]).
        uniq.shuffle.first(50)
    else
      group_1 = User.order("reputation_modifier DESC").limit(100).to_a
      group_2 = User.where("articles_count > ?", 5).
        order("twitter_following_count DESC").limit(100).to_a
      group_3 = User.order("comments_count DESC").limit(100).to_a
      users = (group_1 + group_2 + group_3 - [user]).
        uniq.shuffle.first(50)
    end
    users
  end

  def tagged_article_user_ids
    Article.
      tagged_with(user.decorate.cached_followed_tag_names, any: true).
      where(published: true).
      where("positive_reactions_count > ?", 1).pluck(:user_id).
      each_with_object(Hash.new(0)) { |value, counts| counts[value] += 1 }.
      sort_by { |_key, value| value }.
      map { |arr| arr[0] }
  end
end