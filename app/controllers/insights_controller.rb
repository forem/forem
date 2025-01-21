class InsightsController < ApplicationController
  def create
    insights_params = params.require(:insight).permit(
      :event_type,
      :event_name,
      :object_id,
      :index_name,
      :query_id,
      :timestamp
    )

    # Ensure all required parameters are present
    required_fields = [:event_type, :event_name, :object_id, :index_name, :timestamp]
    missing_fields = required_fields - insights_params.keys.map(&:to_sym)
    unless missing_fields.empty?
      render json: { error: "Missing required parameters: #{missing_fields.join(', ')}" }, status: :unprocessable_entity
      return
    end

    # Prepare values for AlgoliaInsightsService
    user_id = current_user&.id&.to_s
    timestamp = insights_params[:timestamp].to_i

    algolia_service = AlgoliaInsightsService.new
    algolia_service.track_event(
      insights_params[:event_type],
      insights_params[:event_name],
      user_id,
      insights_params[:object_id],
      insights_params[:index_name],
      timestamp,
      insights_params[:query_id]
    )

    render json: { message: "Insight processed" }, status: :ok
  rescue ActionController::ParameterMissing => e
    render json: { error: "Error sending insight: #{e.param}" }, status: :unprocessable_entity
  end
end
