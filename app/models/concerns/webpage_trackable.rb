module WebpageTrackable
  extend ActiveSupport::Concern

  included do
    has_many :webpage_references, as: :record, dependent: :delete_all

    after_commit :queue_webpage_sync, on: [:create, :update], if: :saved_change_to_body_markdown?
  end

  private

  def queue_webpage_sync
    SyncWebpageReferencesWorker.perform_async(self.class.name, id)
  end
end
