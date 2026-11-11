class SyncLiquidEmbedReferencesWorker
  include Sidekiq::Job
  sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

  # Postgres btree index rows are capped at 2704 bytes, and url is indexed with tag_name.
  MAX_URL_BYTES = 2000

  def perform(record_class_name, record_id)
    record_class = record_class_name.safe_constantize
    return unless record_class

    record = record_class.find_by(id: record_id)
    return unless record

    embed_data = LiquidEmbedExtractor.extract(record)

    if embed_data.empty?
      return unless record.liquid_embed_references.exists?

      had_feed_refs = record.liquid_embed_references.exists?(tag_name: LiquidEmbedReference::FEED_TAG_NAMES)
      record.liquid_embed_references.delete_all
      LiquidEmbedReference.bust_feed_targets_cache! if had_feed_refs
      return
    end

    had_feed_refs = record.liquid_embed_references.exists?(tag_name: LiquidEmbedReference::FEED_TAG_NAMES)
    has_new_feed_refs = embed_data.any? { |data| LiquidEmbedReference::FEED_TAG_NAMES.include?(data[:tag_name]) }
    is_published = LiquidEmbedReference.record_published?(record)
    now = Time.current

    LiquidEmbedReference.transaction do
      # 1. Clear out all existing embeds
      record.liquid_embed_references.delete_all

      # 2. Bulk insert new items
      embeds_to_insert = embed_data.map do |data|
        {
          record_type: record_class_name,
          record_id: record.id,
          tag_name: data[:tag_name],
          url: data[:url]&.truncate_bytes(MAX_URL_BYTES, omission: nil),
          referenced_type: data[:referenced_type],
          referenced_id: data[:referenced_id],
          options: data[:options],
          published: is_published,
          published_at: record.respond_to?(:published_at) ? record.published_at : record.updated_at,
          score: record.respond_to?(:score) ? record.score : 0,
          created_at: now,
          updated_at: now
        }
      end

      LiquidEmbedReference.insert_all(embeds_to_insert)
    end

    LiquidEmbedReference.bust_feed_targets_cache! if had_feed_refs || has_new_feed_refs
  end
end
