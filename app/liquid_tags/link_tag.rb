class LinkTag < LiquidTagBase
  include ActionView::Helpers
  PARTIAL = "articles/liquid".freeze

  def initialize(_tag_name, slug_or_path_or_url, _tokens)
    @slug_or_path_or_url = ActionController::Base.helpers.strip_tags(slug_or_path_or_url).strip

    def article_hash
      path = Addressable::URI.parse(@slug_or_path_or_url).path
      path.slice!(0) if path.starts_with?("/") # remove leading slash if present
      path.slice!(-1) if path.ends_with?("/") # remove trailing slash if present
      template = Addressable::Template.new("{username}/{slug}")
      template.extract(path)&.symbolize_keys
    end

    @hash = article_hash

    def render(_context)
      article = get_article
      title =  strip_tags article.title
      profile_img = ProfileImage.new(article.user).get(150)
      ActionController::Base.new.render_to_string(
        partial: PARTIAL,
        locals: {
          article: article,
          title: title,
          profile_img: profile_img,
        },
      )
    end

    def get_article
      find_article_by_user(@hash) || find_article_by_org(@hash)
    rescue ActiveRecord::RecordNotFound
      raise StandardError, "Invalid link URL or link URL does not exist"
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
end

Liquid::Template.register_tag("link", LinkTag)
