# Utilities methods to safely build app wide URLs
module URL
  def self.protocol
    ApplicationConfig["APP_PROTOCOL"]
  end

  def self.domain
    ApplicationConfig["APP_DOMAIN"]
  end

  # Creates an app URL
  #
  # @note Uses protocol and domain specified in the environment, ensure they are set.
  # @param uri [URI, String] parts we want to merge into the URL, e.g. path, fragment
  # @example Retrieve the base URL
  #  app_url #=> "https://dev.to"
  # @example Add a path
  #  app_url("internal") #=> "https://dev.to/internal"
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
  end
end
