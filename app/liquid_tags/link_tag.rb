class LinkTag < LiquidTagBase
  include ActionView::Helpers
  attr_reader :article

  def initialize(_tag_name, slug_or_path_or_url, _tokens)
    @article = parse_url_for_article(slug_or_path_or_url)
  end

  def render(_context)
    tags = article.tag_list.map { |t| "<span class='ltag__link__tag'>##{t}</span>" }.join
    <<-HTML
      <div class='ltag__link'>
        <a href='#{article.user.path}' class='ltag__link__link'>
          <div class='ltag__link__pic'>
            <img src='#{ProfileImage.new(article.user).get(150)}' alt='#{article.user.username} image'/>
          </div></a>
          <a href='#{article.path}' class='ltag__link__link'>
            <div class='ltag__link__content'>
              <h2>#{strip_tags article.title}</h2>
              <h3>#{article.user.name}</h3>
              <div class='ltag__link__taglist'>#{tags}</div>
            </div>
        </a>
      </div>
    HTML
  end

  private

  def parse_url_for_article(slug_or_path_or_url)
    slug_or_path_or_url = ActionController::Base.helpers.strip_tags(slug_or_path_or_url).strip

    hash = article_hash(slug_or_path_or_url)

    raise_error if hash.nil?

    article = find_article_by_user(hash) || find_article_by_org(hash)
    raise_error unless article
    article
  rescue StandardError
    raise_error
  end

  def article_hash(slug_or_path_or_url)
    path = Addressable::URI.parse(slug_or_path_or_url).path
    path.slice!(0) if path.starts_with?("/") # remove leading slash if present
    path.slice!(-1) if path.ends_with?("/") # remove trailing slash if present
    template = Addressable::Template.new("{username}/{slug}")
    template.extract(path)&.symbolize_keys
  end

  def find_article_by_user(hash)
    user = User.find_by_username(hash[:username])
    return unless user
    user.articles.where(slug: hash[:slug])&.first
  end

  def find_article_by_org(hash)
    org = Organization.find_by_slug(hash[:username])
    return unless org
    org.articles.where(slug: hash[:slug])&.first
  end

  def raise_error
    raise StandardError, "Invalid link URL or link URL does not exist"
  end
end

Liquid::Template.register_tag("link", LinkTag)
