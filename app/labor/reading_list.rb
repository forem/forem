class ReadingList
  attr_accessor :user
  def initialize(user)
    @user = user
  end

  def get
    Article.
      joins(:reactions).
      includes(:user).
      where(reactions: reaction_criteria).
      order("reactions.created_at DESC")
  end

  def cached_ids_of_articles
    Rails.cache.fetch("reading_list_ids_of_articles_#{user.id}_#{user.updated_at.rfc3339}") do
      ids_of_articles
    end
  end

  def ids_of_articles
    Reaction.where(reaction_criteria).order("created_at DESC").pluck(:reactable_id)
  end

  def count
    get.size
  end

  def reaction_criteria
    { user_id: user.id, reactable_type: "Article", category: "readinglist" }
  end
end
