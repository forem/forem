module GithubRepos
  class RepoSyncWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10, lock: :until_executing

    TOUCH_USER_COOLDOWN = 30.minutes

    def perform(repo_id)
      repo = GithubRepo.find_by(id: repo_id)
      return unless repo

      user = repo.user
      return unless user.identities.github.exists?

      begin
        client = Github::OauthClient.for_user(user)
        fetched_repo = client.repository(repo.info_hash[:full_name])

        repo.update!(
          github_id_code: fetched_repo.id,
          name: fetched_repo.name,
          description: fetched_repo.description,
          language: fetched_repo.language,
          fork: fetched_repo.fork,
          bytes_size: fetched_repo.size,
          watchers_count: fetched_repo.watchers,
          stargazers_count: fetched_repo.stargazers_count,
          info_hash: fetched_repo.to_hash,
          # Touch `updated_at` even if nothing here was updated. See PR #12853
          # for more details.
          updated_at: Time.current,
        )
        if repo.user&.github_repos_updated_at&.before?(TOUCH_USER_COOLDOWN.ago)
          repo.user.touch(:github_repos_updated_at)
        end
      rescue Github::Errors::NotFound,
             Github::Errors::Unauthorized,
             Github::Errors::AccountSuspended,
             Github::Errors::RepositoryUnavailable
        repo.destroy
      rescue Github::Errors::ClientError => e
        raise e unless e.message.include?("Repository access blocked")

        repo.destroy
      end
    end
  end
end
