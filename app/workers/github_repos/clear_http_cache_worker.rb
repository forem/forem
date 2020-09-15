module GithubRepos
  class ClearHttpCacheWorker
    include Sidekiq::Worker
    GITHUB_REPOS_URL = "https://api.github.com/user/repos?per_page=100".freeze

    sidekiq_options queue: :medium_priority, retry: 10

    def perform
      return unless SiteConfig.github_key.present? && SiteConfig.github_secret.present?

      # We need a dummy client to access Faraday::HttpCache storage class
      # this client never actually makes any github requests so credentials are not needed
      client = Github::OauthClient.new(client_id: "placeholder")
      middleware_cache = client.middleware.handlers.detect { |h| h == Faraday::HttpCache }

      # Our Github Oauth client uses Faraday::HttpCache (https://github.com/forem/forem/blob/master/app/services/github/oauth_client.rb#L114)
      # to cache request results which can be served in event of an error.
      # The problem with this is every time we fetch github repos we add another request to
      # our Redis key AND we reset the expiration back to 24 hours. This can cause the key in Redis
      # to grow uncontrollably. To prevent the key from getting too large we delete it once a day.
      middleware_cache.build.__send__("storage").delete(GITHUB_REPOS_URL)
    end
  end
end
