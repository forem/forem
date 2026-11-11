module LiquidEmbeddable
  extend ActiveSupport::Concern

  included do
    has_many :liquid_embed_references, as: :record, dependent: :destroy

    after_commit :queue_liquid_embed_sync, on: %i[create update], if: :should_queue_liquid_embed_sync?
    after_commit :sync_liquid_embed_metadata, on: [:update], if: :should_sync_liquid_embed_metadata?
    after_destroy_commit :bust_liquid_embed_feed_targets_cache, if: :current_markdown_has_liquid_tag?
  end

  private

  def should_queue_liquid_embed_sync?
    return false unless liquid_embed_content_changed?

    current_markdown_has_liquid_tag? || previous_markdown_had_liquid_tag?
  end

  def liquid_embed_content_changed?
    (respond_to?(:saved_change_to_body_markdown?) && saved_change_to_body_markdown?) ||
      (respond_to?(:saved_change_to_minimized_body_markdown?) && saved_change_to_minimized_body_markdown?) ||
      (respond_to?(:saved_change_to_render_mode?) && saved_change_to_render_mode?) ||
      (respond_to?(:saved_change_to_template_data?) && saved_change_to_template_data?) ||
      (respond_to?(:saved_change_to_page_template_id?) && saved_change_to_page_template_id?)
  end

  def current_markdown_has_liquid_tag?
    return false if respond_to?(:forem_markdown?) && !forem_markdown?

    (respond_to?(:body_markdown) && body_markdown.to_s.include?("{%")) ||
      (respond_to?(:minimized_body_markdown) && minimized_body_markdown.to_s.include?("{%")) ||
      page_template_has_liquid_tag?
  end

  def page_template_has_liquid_tag?
    return false unless respond_to?(:uses_page_template?) && uses_page_template?

    template_data.to_s.include?("{%") || page_template&.body_markdown.to_s.include?("{%")
  end

  def previous_markdown_had_liquid_tag?
    previous_markdown_fields.any? { |value| value.to_s.include?("{%") } ||
      page_template_changed? ||
      switched_from_markdown_with_liquid_tag?
  end

  def previous_markdown_fields
    fields = []
    fields << saved_change_to_body_markdown&.first if respond_to?(:saved_change_to_body_markdown)
    fields << saved_change_to_minimized_body_markdown&.first if respond_to?(:saved_change_to_minimized_body_markdown)
    fields << saved_change_to_template_data&.first if respond_to?(:saved_change_to_template_data)
    fields
  end

  def page_template_changed?
    respond_to?(:saved_change_to_page_template_id?) && saved_change_to_page_template_id?
  end

  def switched_from_markdown_with_liquid_tag?
    return false unless respond_to?(:saved_change_to_render_mode?) && saved_change_to_render_mode?
    return false unless saved_change_to_render_mode&.first == "forem_markdown"

    body_markdown.to_s.include?("{%") || minimized_body_markdown.to_s.include?("{%")
  end

  def should_sync_liquid_embed_metadata?
    return false unless current_markdown_has_liquid_tag?
    return true if liquid_embed_visibility_changed?

    return false unless respond_to?(:saved_change_to_score?) && saved_change_to_score?

    !liquid_embed_score_sync_throttled?
  end

  def liquid_embed_visibility_changed?
    (respond_to?(:saved_change_to_published?) && saved_change_to_published?) ||
      (respond_to?(:saved_change_to_published_at?) && saved_change_to_published_at?) ||
      (respond_to?(:saved_change_to_approved?) && saved_change_to_approved?) ||
      (respond_to?(:saved_change_to_expires_at?) && saved_change_to_expires_at?)
  end

  def liquid_embed_score_sync_throttled?
    backoff = LiquidEmbedReference.record_engagement_backoff(self)
    return false if backoff < LiquidEmbedReference::COOLDOWN_GATE_THRESHOLD

    cache_key = "liquid_embed_references:meta_score_cd:v1:#{self.class.name}:#{id}"
    Rails.cache.write(cache_key, true, unless_exist: true, expires_in: backoff) == false
  end

  def sync_liquid_embed_metadata
    return unless current_markdown_has_liquid_tag?

    updated_count = liquid_embed_references.update_all(
      score: respond_to?(:score) ? score : 0,
      published: LiquidEmbedReference.record_published?(self),
      published_at: LiquidEmbedReference.record_published_at(self),
    )
    LiquidEmbedReference.bust_feed_targets_cache! if updated_count.positive? && is_a?(Billboard)
  end

  def bust_liquid_embed_feed_targets_cache
    LiquidEmbedReference.bust_feed_targets_cache!
  end

  def queue_liquid_embed_sync
    SyncLiquidEmbedReferencesWorker.perform_async(self.class.name, id)
  end
end
