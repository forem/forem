class BoostedArticle
  attr_accessor :user, :article, :tags, :not_ids
  def initialize(user, article, options)
    @user = user
    @article = article
    @tags = (user&.cached_followed_tag_names.to_a + article.decorate.cached_tag_list_array).compact
    @not_ids = options[:not_ids]
  end

  def get(area = "additional_articles")
    if area == "additional_articles"
      Article.boosted_via_additional_articles.
        includes(:user).
        includes(:organization).
        where.not(id: not_ids, organization_id: nil).
        tagged_with(tags, any: true).sample
    else
      Article.boosted_via_dev_digest_email.
        includes(:user).
        includes(:organization).
        where.not(id: not_ids, organization_id: nil).
        tagged_with(tags, any: true).sample
    end
  end
end
