class LinkTag < LiquidTagBase
  include ActionView::Helpers
  PARTIAL = "articles/liquid".freeze

  def initialize(_tag_name, slug_or_path_or_url, _parse_context)
    super
    @article = get_article(slug_or_path_or_url)
    @title = @article.title if @article
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: { article: @article, title: @title },
    )
  end

  def get_article(slug)
    slug = ActionController::Base.helpers.strip_tags(slug).strip
    find_article_by_user(article_hash(slug)) || find_article_by_org(article_hash(slug))
  end

  def article_hash(slug)
    url = Addressable::URI.parse(slug)
    domain = url.port ? "#{url.host}:#{url.port}" : url.host
    path = url.path

    # If domain is present in url check if it belongs to the app
    unless domain.blank? || domain&.casecmp?(Settings::General.app_domain)
      raise StandardError, "The article you're looking for does not exist: {% link #{slug} %}"
    end

    path.slice!(0) if path.starts_with?("/") # remove leading slash if present
    path.slice!(-1) if path.ends_with?("/") # remove trailing slash if present
    extracted_hash = Addressable::Template.new("{username}/{slug}").extract(path)&.symbolize_keys
    raise StandardError, "The article you're looking for does not exist: {% link #{slug} %}" unless extracted_hash

    extracted_hash
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
Liquid::Template.register_tag("post", LinkTag)
