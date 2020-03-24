module App
  module_function

  def protocol
    ApplicationConfig["APP_PROTOCOL"]
  end

  def domain
    ApplicationConfig["APP_DOMAIN"]
  end

  # Creates an app internal URL
  #
  # @note Uses protocol and domain specified in the environment, ensure they are set.
  # @param uri [URI, String] parts we want to merge into the URL, e.g. path, fragment
  # @example Retrieve the base URL
  #  app_url #=> "https://dev.to"
  # @example Add a path
  #  app_url("internal") #=> "https://dev.to/internal"
  def url(uri = nil)
    base_url = "#{protocol}#{domain}"
    return base_url unless uri

    URI.parse(base_url).merge(uri).to_s
  end
end
