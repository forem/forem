class ClassicArticle
  attr_accessor :user
  def initialize(user)
    @user = user
  end

  def get
    possible_articles = []
    5.times do
      possible_articles << cached_qualifying_article
    end
    possible_articles.compact.sample
  end

  def cached_qualifying_article
    Rails.cache.fetch("classic-article-for-tag-#{random_supported_tag_name}_#{rand(0..1)}", expires_in: 45.minutes) do
      Article.tagged_with(random_supported_tag_name).
        where(published: true, featured: true).
        where("positive_reactions_count > ?", minimum_reaction_count).
        where("published_at > ?", 10.months.ago).
        order("RANDOM()").
        first
    end
  end

  def random_supported_tag_name
    user.decorate.cached_followed_tags.where(supported: true).where.not(name: "ama").sample&.name
  end

  def minimum_reaction_count
    if Rails.env.production?
      36
    else
      1
    end
  end
end
