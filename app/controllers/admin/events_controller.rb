module Admin
  class EventsController < Admin::ApplicationController
    before_action :set_event, only: %i[edit update destroy]

    def index
      @events = Event.all.order(created_at: :desc)
    end

    def new
      @event = Event.new
    end

    def create
      @event = Event.new(event_params)
      if @event.save
        redirect_to admin_events_path, notice: "Event created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @event.update(event_params)
        redirect_to admin_events_path, notice: "Event updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @event.destroy
      redirect_to admin_events_path, notice: "Event destroyed successfully."
    end

    private

    def set_event
      @event = Event.find(params[:id])
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
