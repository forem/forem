class LinkTag < LiquidTagBase
  include ActionView::Helpers
  PARTIAL = "articles/liquid".freeze

  def initialize(_tag_name, slug_or_path_or_url, _tokens)
    @slug_or_path_or_url = ActionController::Base.helpers.strip_tags(slug_or_path_or_url).strip

    class << self
      def article_hash
        path = Addressable::URI.parse(@slug_or_path_or_url).path
        path.slice!(0) if path.starts_with?("/") # remove leading slash if present
        path.slice!(-1) if path.ends_with?("/") # remove trailing slash if present
        Addressable::Template.new("{username}/{slug}").extract(path)&.symbolize_keys
      end
    end

    @hash = article_hash

    class << self
      def render(_context)
        article = get_article
        title = strip_tags article.title
        profile_img = ProfileImage.new(article.user).get(150)
        ActionController::Base.new.render_to_string(
          partial: PARTIAL, locals: { article: article, title: title, profile_img: profile_img },
        )
      end

      def get_article
        User.find_by(username: @hash[:username]).articles.where(slug: @hash[:slug])&.first || Organization.find_by(slug: @hash[:username]).articles.where(slug: @hash[:slug])&.first
      rescue ActiveRecord::RecordNotFound
        raise StandardError, "Invalid link URL or link URL does not exist"
      end
    end
  end
end

Liquid::Template.register_tag("link", LinkTag)
