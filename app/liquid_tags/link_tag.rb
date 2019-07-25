class LinkTag < LiquidTagBase
  include ActionView::Helpers
  PARTIAL = "articles/liquid".freeze

  def initialize(_tag_name, slug_or_path_or_url, _tokens)
    @article = get_article(slug_or_path_or_url)
    @title = @article.title
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: { article: @article, title: @title },
    )
  end

  def get_article(slug)
    slug = ActionController::Base.helpers.strip_tags(slug).strip
    article = find_article_by_user(article_hash(slug)) || find_article_by_org(article_hash(slug))
    raise StandardError, "Invalid link URL or link URL does not exist" unless article

    article
  end

  def article_hash(slug)
    path = Addressable::URI.parse(slug).path
    path.slice!(0) if path.starts_with?("/") # remove leading slash if present
    path.slice!(-1) if path.ends_with?("/") # remove trailing slash if present
    Addressable::Template.new("{username}/{slug}").extract(path)&.symbolize_keys
  end

  def find_article_by_user(hash)
    user = User.find_by(username: hash[:username])
    return unless user

    user.articles.where(slug: hash[:slug])&.first
  end

  def find_article_by_org(hash)
    org = Organization.find_by(slug: hash[:username])
    return unless org

    org.articles.where(slug: hash[:slug])&.first
  end
end

Liquid::Template.register_tag("link", LinkTag)
