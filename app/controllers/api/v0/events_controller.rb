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
        if request.headers["api-key"]
          authenticate!
        end
      end

      def set_event
        @event = Event.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Event not found" }, status: :not_found
      end

      def event_params
        params.require(:event).permit(
          :title, 
          :event_name_slug,
          :event_variation_slug,
          :description, 
          :primary_stream_url, 
          :published, 
          :start_time, 
          :end_time, 
          :type_of, 
          :user_id, 
          :organization_id, 
          :tag_list,
          data: {}
        )
      end
    end
  end
end
