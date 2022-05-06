module Organizations
  class UpdateOrganizationArticlesPathsWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority

    def perform(organization_id, old_slug, new_slug)
      organization = Organization.find_by(id: organization_id)

      return unless organization

      organization.articles.find_each do |article|
        article.update(path: article.path.gsub(old_slug, new_slug))
      end
    end
  end
end
