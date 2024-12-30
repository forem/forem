# Utilities methods to safely build app wide URLs
module URL
  def self.protocol
    ApplicationConfig["APP_PROTOCOL"]
  end

  def self.database_available?
    ActiveRecord::Base.connected? && has_site_configs?
  end

  private_class_method :database_available?

  def self.has_site_configs?
    @has_site_configs ||= ActiveRecord::Base.connection.table_exists?("site_configs")
  end

  private_class_method :has_site_configs?

  def self.domain(subforem = nil)
    if subforem
      subforem.domain
    elsif database_available?
      Settings::General.app_domain
    else
      ApplicationConfig["APP_DOMAIN"]
    end
  end

  def self.url(uri = nil, subforem = nil)
    base_url = "#{protocol}#{domain(subforem)}"
    base_url += ":3000" if Rails.env.development? && !base_url.include?(":3000")
    return base_url unless uri
    Addressable::URI.parse(base_url).join(uri).normalize.to_s
  end

  # Creates an article URL
  #
  # @param article [Article] the article to create the URL for
  def self.article(article)
    subforem = article.subforem || Subforem.find_by(id: RequestStore.store[:default_subforem_id]) if article.respond_to?(:subforem_id)
    url(article.path, subforem)
  end

  # Creates a comment URL
  #
  # @param comment [Comment] the comment to create the URL for
  def self.comment(comment)
    subforem =  if comment.commentable.class.name == "Article" && comment.commentable.respond_to?(:subforem_id)
                  comment.commentable.subforem || Subforem.find_by(id: RequestStore.store[:default_subforem_id])
                else
                  Subforem.find_by(id: RequestStore.store[:subforem_id])
                end
    url(comment.path, subforem)
  end

  # Creates a fragment URL for a comment on an article page
  # if an article path is available
  #
  # @param comment [Comment] the comment to create the URL for
  # @param path [String, nil] the path of the article to anchor the
  #   comment link instead of using the comment's permalink
  def self.fragment_comment(comment, path:)
    return comment(comment) if path.nil?

    url("#{path}#comment-#{comment.id_code}")
  end

  # Creates a reaction URL
  #
  # A reaction URL is the URL of its reactable.
  #
  # @param reaction [Reaction, #reactable] the reaction to create the URL for
  # @return [String]
  # @see .url
  def self.reaction(reaction)
    url(reaction.reactable.path)
  end

  # Creates a tag URL
  #
  # @param tag [Tag] the tag to create the URL for
  def self.tag(tag, page = 1)
    url([tag_path(tag), ("/page/#{page}" if page > 1)].join)
  end

  def self.tag_path(tag)
    "/t/#{CGI.escape(tag.name)}"
  end

  # Creates a user URL
  #
  # @param user [User] the user to create the URL for
  def self.user(user)
    url(user.username)
  rescue URI::InvalidURIError # invalid username containing spaces will result in an error
    nil
  end

  # Creates an Image URL - a shortcut for the .image_url helper
  #
  # @param image_name [String] the image file name
  # @param host [String] (optional) the host for the image URL you'd like to use
  def self.local_image(image_name, host: nil)
    host ||= ActionController::Base.asset_host || url(nil)
    ActionController::Base.helpers.image_url(image_name, host: host)
  end

  # Creates a deep link URL (for mobile) to a page in the current Forem and it
  # relies on a UDL server to bounce back mobile users to the local `/r/mobile`
  # fallback page. More details here: https://github.com/forem/udl-server
  #
  # @param path [String] the target path to deep link
  def self.deep_link(path)
    target_path = CGI.escape(url("/r/mobile?deep_link=#{path}"))
    "https://udl.forem.com/?r=#{target_path}"
  end

  def self.organization(organization)
    url(organization.slug)
  end
end
