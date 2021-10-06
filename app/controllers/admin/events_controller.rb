module Admin
  class EventsController < ApplicationController
    layout "admin"
    include ApplicationHelper

    EVENTS_ALLOWED_PARAMS = %i[
      title category event_date starts_at ends_at
      location_name cover_image location_url description_markdown published
      host_name profile_image live_now
    ].freeze

    def index
      @events = Event.order(starts_at: :desc).page(params[:page]).per(20)
    end

    def new
      @event = Event.new(
        location_name: "#{URL.domain}/live",
        location_url: app_url,
        description_markdown: "*Description* *Pre-requisites:* *Bio*",
      )
    end

    def edit
      @event = Event.find(params[:id])
    end

    def create
      @event = Event.new(event_params)
      if @event.save
        flash[:success] = "Successfully created event: #{@event.title}"
        redirect_to admin_events_path
      else
        flash[:danger] = @event.errors.full_messages
        render :new
      end
    end

    def update
      @event = Event.find(params[:id])
      if @event.update(event_params)
        flash[:success] = "#{@event.title} was successfully updated"
        redirect_to admin_events_path
      else
        flash[:danger] = @event.errors.full_messages
        render :edit
      end
    end

    private

    def event_params
      params.require(:event).permit(EVENTS_ALLOWED_PARAMS)
    end
  end
end
