module Internal
  class EventsController < ApplicationController
    layout "internal"
    def index
      @events = Event.order("starts_at ASC")
      @event = Event.new(location_name: "dev.to/live",
        location_url: "https://dev.to",
        description_markdown: "*Description* *Pre-requisites:* *Bio*" )
    end

    def create
      @event = Event.create!(event_params)
      redirect_to(action: :index)
    rescue ActiveRecord::RecordInvalid => error
      flash[:alert] = error.message
      redirect_to(action: :index)
    end

    def update
      @event = Event.find(params[:id])
      @event.update(event_params)
    end

    private

    def event_params
      params.require(:event).permit(:title,
                                  :category,
                                  :event_date,
                                  :starts_at,
                                  :ends_at,
                                  :location_name,
                                  :cover_image,
                                  :location_url,
                                  :description_markdown,
                                  :published)
    end
  end
end
