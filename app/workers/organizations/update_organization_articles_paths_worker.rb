module Organizations
  class UpdateOrganizationArticlesPathsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(organization_id, old_slug, new_slug)
      articles = Organization.find_by(id: organization_id).articles
      articles.find_each { |article| article.update(path: article.path.gsub(old_slug, new_slug)) }
    end
  end
end
