module Html
  class ImageUri
    GITHUB_CAMO = {
      scheme: "https",
      host: "camo.githubusercontent.com"
    }.freeze

    GITHUB_BADGE = {
      scheme: "https",
      host: "github.com",
      filename: "badge.svg"
    }.freeze

    attr_reader :uri, :original_source

    delegate :scheme, :host, :path, to: :uri

    def initialize(src)
      @uri = URI(src)
      @original_source = src
    end

    def allowed?
      github_camo_user_content? || github_badge?
    end

    def github_badge?
      scheme == GITHUB_BADGE[:scheme] &&
        host == GITHUB_BADGE[:host] &&
        filename == GITHUB_BADGE[:filename]
    end

    def github_camo_user_content?
      scheme == GITHUB_CAMO[:scheme] && host == GITHUB_CAMO[:host]
    end

    private

    def filename
      File.basename path
    end
  end
end
