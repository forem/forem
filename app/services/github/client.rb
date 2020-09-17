module Github
  # Github client with Application Authentication (uses ocktokit.rb as a backend)
  class Client
    def initialize
      OauthClient.new(
        client_id: SiteConfig.github_key,
        client_secret: SiteConfig.github_secret,
      )
    end
  end
end
