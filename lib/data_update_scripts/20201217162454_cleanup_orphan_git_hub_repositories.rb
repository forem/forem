module DataUpdateScripts
  class CleanupOrphanGitHubRepositories
    def run
      # load orphan GithubRepo ids
      rows = ActiveRecord::Base.connection.execute(
        <<-SQL,
          SELECT id FROM github_repos
          WHERE user_id NOT IN (
            SELECT users.id FROM users
            JOIN identities ON users.id = identities.user_id
            WHERE provider = 'github'
          )
        SQL
      )

      github_repos_ids = rows.map { |row| row["id"] }

      # load them in batches and delete them from AR so that we can trigger the after_destroy callbacks
      GithubRepo.where(id: github_repos_ids).find_each(&:destroy)
    end
  end
end
