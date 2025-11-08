# Backfill selection_weights for existing BillboardPlacementAreaConfig records
# This ensures configs created before the weights feature are properly initialized
Rails.application.config.after_initialize do
  # Only run in contexts where ActiveRecord is available and migrations have run
  next unless defined?(ActiveRecord::Base)
  
  # Safely check if table and column exist
  begin
    next unless ActiveRecord::Base.connection.table_exists?(:billboard_placement_area_configs)
    next unless ActiveRecord::Base.connection.column_exists?(:billboard_placement_area_configs, :selection_weights)
  rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad => e
    Rails.logger.debug("Skipping billboard config backfill: #{e.message}")
    next
  end

  # Backfill weights for any configs that don't have them set
  BillboardPlacementAreaConfig.find_each do |config|
    next if config.selection_weights.present? && !config.selection_weights.empty?

    begin
      config.initialize_weights_from_app_config
      if config.changed?
        # Use update_columns to skip callbacks and validations during initialization
        config.save!(validate: false)
      end
    rescue StandardError => e
      Rails.logger.warn("Failed to initialize weights for placement area #{config.placement_area}: #{e.message}")
      Rails.logger.debug(e.backtrace.join("\n"))
    end
  end
rescue StandardError => e
  # Catch any unexpected errors during the entire backfill process
  Rails.logger.error("Billboard placement area config backfill failed: #{e.message}")
  Rails.logger.debug(e.backtrace.join("\n"))
end

