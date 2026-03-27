class SyncLiquidEmbedReferencesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low

  def perform(record_class_name, record_id)
    record_class = record_class_name.safe_constantize
    return unless record_class

    record = record_class.find_by(id: record_id)
    return unless record

    embed_data = LiquidEmbedExtractor.extract(record)
    
    LiquidEmbedReference.transaction do
      # 1. Clear out all existing embeds
      record.liquid_embed_references.delete_all

      # 2. Bulk insert new items
      if embed_data.any?
        embeds_to_insert = embed_data.map do |data|
          {
            record_type: record_class_name,
            record_id: record.id,
            tag_name: data[:tag_name],
            url: data[:url],
            referenced_type: data[:referenced_type],
            referenced_id: data[:referenced_id],
            options: data[:options],
            published: record.respond_to?(:published) ? record.published : true,
            published_at: record.respond_to?(:published_at) ? record.published_at : record.updated_at,
            score: record.respond_to?(:score) ? record.score : 0,
            created_at: Time.current,
            updated_at: Time.current
          }
        end

        LiquidEmbedReference.insert_all(embeds_to_insert)
      end
    end
  end
end
