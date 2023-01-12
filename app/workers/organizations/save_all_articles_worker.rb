module Organizations
  class SaveAllArticlesWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority

    def perform(organization_id)
      organization = Organization.find_by(id: organization_id)
      organization.articles.find_each(&:save)
    end
  end
end
