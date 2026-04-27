class SyncWebpageReferencesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low_priority

  def perform(record_class_name, record_id)
    record_class = record_class_name.safe_constantize
    return unless record_class

    record = record_class.find_by(id: record_id)
    return unless record

    urls = WebpageExtractor.extract(record)
    
    WebpageReference.transaction do
      # 1. Clear out existing references for this record
      record.webpage_references.delete_all

      # 2. Process and insert new references
      if urls.any?
        references_to_insert = []
        urls.each do |url|
          domain = LinkedDomain.find_or_create_by_url(url)
          next unless domain

          references_to_insert << {
            record_type: record_class_name,
            record_id: record.id,
            linked_domain_id: domain.id,
            url: url,
            created_at: Time.current,
            updated_at: Time.current
          }
        end

        WebpageReference.insert_all(references_to_insert) if references_to_insert.any?
      end
    end
    
    # Trigger score update for the domains involved
    # (Optional: we could do this more efficiently in bulk)
  end
end
