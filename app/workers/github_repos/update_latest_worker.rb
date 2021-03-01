module GithubRepos
  class UpdateLatestWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform
      GithubRepo.update_to_latest
    end
  end
end
