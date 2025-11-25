module PageTemplates
  class ReRenderPagesWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 3

    def perform(page_template_id)
      page_template = PageTemplate.find_by(id: page_template_id)
      return unless page_template

      page_template.pages.find_each do |page|
        page.re_render_from_template!
      rescue StandardError => e
        Rails.logger.error("Failed to re-render page #{page.id} from template #{page_template_id}: #{e.message}")
      end
    end
  end
end

