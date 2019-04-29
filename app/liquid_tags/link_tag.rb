class LinkTag < LiquidTagBase
  include ActionView::Helpers
  # attr_reader :article
  PARTIAL = "articles/liquid".freeze

  def initialize(_tag_name, slug_or_path_or_url, _tokens)

    def render(_context)
      article = parse_url_for_article(slug_or_path_or_url)
      title = strip_tags article.title
      profile_img = ProfileImage.new(article.user).get(150)
      tags = article.tag_list.map { |t| "<span class='ltag__link__tag'>##{t}</span>" }.join
      ActionController::Base.new.render_to_string(
        partial: PARTIAL,
        locals: {
          article: article,
          title: title,
          profile_img: profile_img,
          tags: tags,
        },
      )
    end

    def parse_url_for_article(slug_or_path_or_url)
      slug_or_path_or_url = ActionController::Base.helpers.strip_tags(slug_or_path_or_url).strip

      hash = article_hash(slug_or_path_or_url)

      raise_error if hash.nil?

      article = find_article_by_user(hash) || find_article_by_org(hash)
      raise_error unless article
      article
    rescue StandardError
      raise StandardError, "Invalid link URL or link URL does not exist"
    end

    def article_hash(slug_or_path_or_url)
      path = Addressable::URI.parse(slug_or_path_or_url).path
      path.slice!(0) if path.starts_with?("/") # remove leading slash if present
      path.slice!(-1) if path.ends_with?("/") # remove trailing slash if present
      template = Addressable::Template.new("{username}/{slug}")
      template.extract(path)&.symbolize_keys
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
