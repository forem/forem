namespace :collection_id_aliases do
  desc "Backfill CollectionIdAlias records from explicit ID mappings. Usage: MAPPINGS='123:456,124:457' DRY_RUN=1 bin/rake collection_id_aliases:backfill_from_mapping"
  task backfill_from_mapping: :environment do
    mappings = ENV.fetch("MAPPINGS", "").split(",").map(&:strip).reject(&:blank?)

    if mappings.empty?
      raise "MAPPINGS is required. Example: MAPPINGS='123:456,124:457'"
    end

    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", "true"))
    created = 0
    skipped = 0

    mappings.each do |mapping|
      legacy_id_raw, current_id_raw = mapping.split(":", 2)
      legacy_id = legacy_id_raw.to_i
      current_id = current_id_raw.to_i

      if legacy_id <= 0 || current_id <= 0
        puts "SKIP invalid mapping format: #{mapping.inspect}"
        skipped += 1
        next
      end

      legacy_collection = Collection.find_by(id: legacy_id)
      current_collection = Collection.find_by(id: current_id)

      if legacy_collection.blank? || current_collection.blank?
        puts "SKIP missing collection record for mapping #{legacy_id}:#{current_id}"
        skipped += 1
        next
      end

      unless legacy_collection.slug == current_collection.slug && legacy_collection.user_id == current_collection.user_id
        puts "SKIP safety check failed for #{legacy_id}:#{current_id} (slug/user mismatch)"
        skipped += 1
        next
      end

      if dry_run
        puts "DRY RUN create alias #{legacy_id} -> #{current_id}"
        next
      end

      CollectionIdAlias.find_or_create_by!(legacy_collection_id: legacy_id) do |alias_record|
        alias_record.collection_id = current_id
      end
      puts "CREATED alias #{legacy_id} -> #{current_id}"
      created += 1
    end

    puts "Backfill complete: created=#{created}, skipped=#{skipped}, dry_run=#{dry_run}"
  end
end
