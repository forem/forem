module WebpageTrackable
  extend ActiveSupport::Concern

  included do
    has_many :webpage_references, as: :record, dependent: :delete_all

    after_commit :queue_webpage_sync, on: [:create, :update], if: :saved_change_to_body_markdown?
    before_destroy :capture_webpage_domains, prepend: true
    after_destroy_commit :queue_webpage_domain_updates
  end

  private

  def queue_webpage_sync
    SyncWebpageReferencesWorker.perform_async(self.class.name, id)
  end

  def capture_webpage_domains
    @_webpage_domains_to_update = webpage_references.pluck(:linked_domain_id)
  end

  def queue_webpage_domain_updates
    Array(@_webpage_domains_to_update).each do |domain_id|
      LinkedDomains::UpdateScoreWorker.perform_async(domain_id)
    end
  end
end
