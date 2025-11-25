module Admin
  class BillboardPlacementAreaConfigsController < Admin::ApplicationController
    layout "admin"

    def index
      @configs = BillboardPlacementAreaConfig.order(:placement_area)
      
      # Create configs for any missing placement areas
      missing_areas = Billboard::ALLOWED_PLACEMENT_AREAS - @configs.pluck(:placement_area)
      missing_areas.each do |area|
        begin
          BillboardPlacementAreaConfig.create!(
            placement_area: area,
            signed_in_rate: 100,
            signed_out_rate: 100
          )
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.warn("Failed to create config for #{area}: #{e.message}")
        end
      end
      
      @configs = BillboardPlacementAreaConfig.order(:placement_area) if missing_areas.any?
    end

    def edit
      @config = BillboardPlacementAreaConfig.find(params[:id])
      @human_readable_area = @config.human_readable_placement_area
    end

    def update
      @config = BillboardPlacementAreaConfig.find(params[:id])

      if @config.update(config_params)
        flash[:success] = "Placement area config updated successfully"
        redirect_to admin_billboard_placement_area_configs_path
      else
        flash[:danger] = @config.errors.full_messages.to_sentence
        render :edit
      end
    end

    private

    def config_params
      permitted = params.require(:billboard_placement_area_config).permit(
        :signed_in_rate,
        :signed_out_rate,
        :cache_expiry_seconds,
        selection_weights: [
          :random_selection,
          :new_and_priority,
          :new_only,
          :weighted_performance,
          :evenly_distributed
        ]
      )
      
      # Sanitize selection_weights to ensure all values are non-negative integers
      if permitted[:selection_weights].present?
        permitted[:selection_weights] = permitted[:selection_weights].transform_values do |v|
          [v.to_i, 0].max
        end
      end
      
      permitted
    end

    def authorize_admin
      authorize Billboard, :access?, policy_class: InternalPolicy
    end
  end
end

