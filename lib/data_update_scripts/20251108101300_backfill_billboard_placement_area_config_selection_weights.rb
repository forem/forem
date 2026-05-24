module DataUpdateScripts
  class BackfillBillboardPlacementAreaConfigSelectionWeights
    def run
      # Backfill selection_weights for any configs that don't have them set
      BillboardPlacementAreaConfig.find_each do |config|
        next if config.selection_weights.present? && !config.selection_weights.empty?

        config.initialize_weights_from_app_config
        config.save! if config.changed?
      rescue StandardError => e
        Rails.logger.warn("Failed to initialize weights for placement area #{config.placement_area}: #{e.message}")
      end
    end
  end
end

