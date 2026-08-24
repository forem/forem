module Api
  module EventsController
    extend ActiveSupport::Concern

    included do
      skip_before_action :verify_authenticity_token, raise: false
      before_action :authenticate_with_api_key_or_current_user!, only: %i[create update destroy]
      before_action :authenticate_with_api_key_or_current_user, only: %i[index show]
      before_action :set_event, only: %i[show update destroy]
    end

    def index
      @events = if @user&.administrative_access_to?(resource: Event)
                  Event.all
                else
                  Event.published
                end
      if params[:type_of].present? && Event.type_ofs.key?(params[:type_of])
        @events = @events.where(type_of: params[:type_of])
      end
      render json: @events.order(created_at: :desc)
    end

    def show
      unless @event.published? || @user&.administrative_access_to?(resource: Event)
        return render json: { error: "Event not found" }, status: :not_found
      end

      render json: @event
    end

    def create
      authorize Event
      @event = Event.new(event_params.except(:user_id))
      @event.user_id = @user.id if @event.user_id.blank?

      if @event.save
        render json: @event, status: :created
      else
        render json: { error: @event.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      authorize @event
      if @event.update(event_params.except(:user_id))
        render json: @event
      else
        render json: { error: @event.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @event
      @event.destroy
      head :no_content
    end

    private

    def set_event
      @event = Event.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Event not found" }, status: :not_found
    end

    def event_params
      permitted = params.require(:event).permit(
        :title,
        :event_name_slug,
        :event_variation_slug,
        :description,
        :full_details,
        :primary_stream_url,
        :published,
        :elevated,
        :start_time,
        :end_time,
        :type_of,
        :broadcast_config,
        :manual_broadcast_end,
        :user_id,
        :organization_id,
        :tag_list,
        :page_id,
        :delegate_to_page,
        :cover_image,
        :cover_image_url,
        :remote_cover_image_url,
        :remove_cover_image,
        :bg_color_hex,
        data: {}
      )

      if permitted[:cover_image_url].present?
        permitted[:remote_cover_image_url] = permitted.delete(:cover_image_url)
      elsif permitted[:cover_image].is_a?(String) && permitted[:cover_image].match?(%r{\Ahttps?://}i)
        permitted[:remote_cover_image_url] = permitted.delete(:cover_image)
      end

      permitted
    end
  end
end
