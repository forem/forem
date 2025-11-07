# Backfill selection_weights for existing BillboardPlacementAreaConfig records
# This ensures configs created before the weights feature are properly initialized
Rails.application.config.after_initialize do
  # Only run in contexts where ActiveRecord is available and migrations have run
  next unless ActiveRecord::Base.connection.table_exists?(:billboard_placement_area_configs)
  next unless ActiveRecord::Base.connection.column_exists?(:billboard_placement_area_configs, :selection_weights)

  # Backfill weights for any configs that don't have them set
  BillboardPlacementAreaConfig.find_each do |config|
    next if config.selection_weights.present? && !config.selection_weights.empty?

    config.initialize_weights_from_app_config
    config.save! if config.changed?
  rescue StandardError => e
    Rails.logger.warn("Failed to initialize weights for placement area #{config.placement_area}: #{e.message}")
  end
end

