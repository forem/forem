module LiquidEmbeddable
  extend ActiveSupport::Concern

  included do
    has_many :liquid_embed_references, as: :record, dependent: :destroy

    after_commit :queue_liquid_embed_sync, on: [:create, :update], if: :saved_change_to_body_markdown?
    after_commit :sync_liquid_embed_metadata, on: [:update], if: :should_sync_liquid_embed_metadata?
  end

  private

  def should_sync_liquid_embed_metadata?
    (respond_to?(:saved_change_to_score?) && saved_change_to_score?) ||
      (respond_to?(:saved_change_to_published?) && saved_change_to_published?) ||
      (respond_to?(:saved_change_to_published_at?) && saved_change_to_published_at?)
  end

  def sync_liquid_embed_metadata
    liquid_embed_references.update_all(
      score: respond_to?(:score) ? score : 0,
      published: respond_to?(:published) ? published : true,
      published_at: respond_to?(:published_at) ? published_at : updated_at
    )
  end

  def queue_liquid_embed_sync
    SyncLiquidEmbedReferencesWorker.perform_async(self.class.name, id)
  end
end
