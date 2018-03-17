class ClassicArticle
  attr_accessor :input, :not_ids
  def initialize(input=nil, options={})
    @input = input
    @not_ids = options[:not_ids]
  end

  def get
    if rand(5) == 1
      random_high_quality_article
    else
      qualifying_articles(random_supported_tag_names).where.not(id: not_ids).compact.sample ||
        random_high_quality_article
    end
  end

  def qualifying_articles(tag_names)
    tag_name = tag_names.sample
    Rails.cache.fetch("classic-article-for-tag-#{tag_name}}", expires_in: 45.minutes) do
      articles = Article.tagged_with(tag_name).
        includes(:user).
        where(published: true, featured: true).
        where("positive_reactions_count > ?", minimum_reaction_count).
        where("published_at > ?", 10.months.ago).
        order("RANDOM()")
    end
  end

  def random_high_quality_article
    Article.where(published: true, featured: true).
      where("positive_reactions_count > ?", minimum_hq_reaction_count).
      includes(:user).
      order("RANDOM()").
      where.not(id: not_ids).
      first
  end

  def random_supported_tag_names
    if input.class.name == "User"
      input.decorate.cached_followed_tags.where(supported: true).where.not(name: "ama").pluck(:name)
    elsif input.class.name == "Article"
      Tag.where(supported: true, name: input.decorate.cached_tag_list_array).where.not(name: "ama").pluck(:name)
    else
      ["discuss"]
    end
  end

  def minimum_reaction_count
    if Rails.env.production?
      45
    else
      1
    end
  end

  def minimum_hq_reaction_count
    if Rails.env.production?
      75
    else
      1
    end
  end
end
