class SyncWebpageReferencesWorker
  include Sidekiq::Job
  sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

  def perform(record_class_name, record_id)
    record_class = record_class_name.safe_constantize
    return unless record_class

    record = record_class.find_by(id: record_id)
    return unless record

    urls = WebpageExtractor.extract(record)
    
    previous_domain_ids = record.webpage_references.pluck(:linked_domain_id)
    current_domain_ids = []

    WebpageReference.transaction do
      # 1. Clear out existing references for this record
      record.webpage_references.delete_all

      # 2. Process and insert new references
      if urls.any?
        references_to_insert = []
        urls.each do |url|
          domain = LinkedDomain.find_or_create_by_url(url)
          next unless domain

          current_domain_ids << domain.id

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
    domain_ids_to_update = (previous_domain_ids + current_domain_ids).uniq
    
    domain_ids_to_update.each do |domain_id|
      LinkedDomains::UpdateScoreWorker.perform_async(domain_id)
    end
  end
end
