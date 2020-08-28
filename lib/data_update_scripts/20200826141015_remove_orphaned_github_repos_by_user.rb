module DataUpdateScripts
  class RemoveOrphanedGithubReposByUser
    def run
      # Delete all Collections belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM github_repos
          WHERE user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
