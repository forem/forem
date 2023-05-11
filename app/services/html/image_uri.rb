module Html
  class ImageUri
    GITHUB_CAMO = "camo.githubusercontent.com".freeze

    attr_reader :uri, :original_source

    delegate :scheme, :host, to: :uri

    def initialize(src)
      @uri = URI(src)
      @original_source = src
    end

    def github_camo_user_content?
      scheme == "https" && host == GITHUB_CAMO
    end
  end
end
