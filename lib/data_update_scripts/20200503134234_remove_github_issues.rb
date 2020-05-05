module DataUpdateScripts
  class RemoveGithubIssues
    def run
      GithubIssue.in_batches.delete_all
    end
  end
end
