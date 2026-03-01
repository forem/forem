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
      github_camo_user_content? || github_badge? || first_party_asset?
    end

    def first_party_asset?
      return true if host.nil? && path.to_s.start_with?("/")

      app_domain = Settings::General.app_domain
      return true if app_domain.present? && host == URI("https://#{app_domain}").host

      asset_host = ActionController::Base.asset_host
      return true if asset_host.present? && host == URI("https://#{asset_host.sub(%r{^https?://}, '')}").host

      false
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
