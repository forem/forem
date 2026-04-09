class EventsController < ApplicationController
  def index
    @events = Event.published.order(start_time: :asc)
  end

  def show
    @event = Event.find_by!(
      event_name_slug: params[:event_name_slug], 
      event_variation_slug: params[:event_variation_slug]
    )
    unless @event.published?
      raise ActionController::RoutingError.new('Not Found')
    end
  end
end
