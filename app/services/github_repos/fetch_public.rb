module GithubRepos
  # Fetches the public repositories a user can pin: their own, plus those of
  # the GitHub organizations they have configured in their settings.
  class FetchPublic
    # @!attribute repositories
    #   @return [Array] unique public repositories, without any particular order
    # @!attribute unreachable_organizations
    #   @return [Array<String>] organizations whose repositories could not be fetched
    #     because of a temporary failure (rate limiting, network or server errors).
    #     Their pinned repositories must be preserved rather than considered removed.
    Result = Struct.new(:repositories, :unreachable_organizations, keyword_init: true)

    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
      @client = Github::OauthClient.for_user(user)
      @unreachable_organizations = []
    end

    # NOTE: GitHub requests are auto-paginated (see config/initializers/octokit.rb)
    # @raise [Github::Errors::Unauthorized, Github::Errors::AccountSuspended] if the GitHub token cannot be used
    def call
      user_repositories = client.repositories(visibility: :public)
      organization_repositories = user.setting.github_organizations.flat_map do |organization|
        fetch_organization_repositories(organization)
      end

      Result.new(
        repositories: (user_repositories + organization_repositories).uniq(&:id),
        unreachable_organizations: unreachable_organizations,
      )
    end

    private

    attr_reader :user, :client, :unreachable_organizations

    def fetch_organization_repositories(organization)
      client.org_repos(organization, type: :public)
    rescue Github::Errors::Unauthorized, Github::Errors::AccountSuspended
      raise
    rescue Github::Errors::NotFound
      # The organization no longer exists (or was renamed): it is confirmed unavailable.
      []
    rescue Github::Errors::Error, Faraday::Error
      unreachable_organizations << organization
      []
    end
  end
end
