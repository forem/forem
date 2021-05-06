# Utilities methods to safely build app wide URLs
module URL
  def self.protocol
    ApplicationConfig["APP_PROTOCOL"]
  end

  def self.domain
    if Rails.application&.initialized? && SiteConfig.respond_to?(:app_domain)
      SiteConfig.app_domain
    else
      ApplicationConfig["APP_DOMAIN"]
    end
  end

  def self.url(uri = nil)
    base_url = "#{protocol}#{domain}"
    return base_url unless uri

    URI.parse(base_url).merge(uri).to_s
  end

  # Creates an article URL
  #
  # @param article [Article] the article to create the URL for
  def self.article(article)
    url(article.path)
  end

  # Creates a comment URL
  #
  # @param comment [Comment] the comment to create the URL for
  def self.comment(comment)
    url(comment.path)
  end

  # Creates a reaction URL
  #
  # A reaction URL is the URL of its reactable.
  #
  # @param reactable [Reaction] the reaction to create the URL for
  def self.reaction(reaction)
    url(reaction.reactable.path)
  end

  # Creates a tag URL
  #
  # @param tag [Tag] the tag to create the URL for
  def self.tag(tag, page = 1)
    url(["/t/#{tag.name}", ("/page/#{page}" if page > 1)].join)
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
    "https://forem-udl-server.herokuapp.com/?r=#{target_path}"
  end

  def self.organization(organization)
    url(organization.slug)
  end
end
