module Api
  module V0
    class EventsController < ApiController
      skip_before_action :verify_authenticity_token, only: %i[create update destroy]
      before_action :authenticate!, except: %i[index show]
      before_action :set_event, only: %i[show update destroy]

      # Authentication is optional for index and show
      # We manually attempt to authenticate to populate current_user if the token is present
      before_action :evaluate_authentication, only: %i[index show]

      def index
        @events = Event.all
        unless @user&.administrative_access_to?(resource: Event)
          @events = @events.published
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
        @event = find_or_initialize_event
        @event.assign_attributes(event_params.except(:user_id))
        @event.user_id = @user.id if @event.user_id.blank?

        if @event.save
          render json: @event, status: @event.previously_new_record? ? :created : :ok
        else
          render json: { error: @event.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @event
        # Prevents arbitrary user hijacking via parameters:
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

      def evaluate_authentication
        # Forem's ApiController usually requires valid token if provided, but optional if omitted.
        # This safely tries to log them in if token is sent.
        return unless request.headers["api-key"]

        authenticate!
      end

      def set_event
        @event = if params[:id].to_s.match?(/\A\d+\z/)
                   Event.find_by(id: params[:id])
                 else
                   Event.find_by(event_name_slug: params[:id])
                 end
        render json: { error: "Event not found" }, status: :not_found unless @event
      end

      def find_or_initialize_event
        if params[:id].present? && params[:id].to_s.match?(/\A\d+\z/)
          Event.find_by(id: params[:id]) || Event.new
        elsif event_params[:event_name_slug].present? && event_params[:event_variation_slug].present?
          Event.find_by(
            event_name_slug: event_params[:event_name_slug],
            event_variation_slug: event_params[:event_variation_slug],
          ) || Event.new
        else
          Event.new
        end
      end

      def event_params
        params.require(:event).permit(
          :title,
          :event_name_slug,
          :event_variation_slug,
          :description,
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
          :remove_cover_image,
          :remote_cover_image_url,
          :bg_color_hex,
          data: {},
        )
      end
    end
  end
end
