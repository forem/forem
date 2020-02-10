class EventsController < ApplicationController
  before_action :set_cache_control_headers, only: [:index]
  # No authorization required for entirely public controller

  def index
    @events = Event.in_the_future_and_published.sort_by(&:starts_at)
    @past_events = Event.in_the_past_and_published.sort_by(&:starts_at)
    set_surrogate_key_header "events_index_page"
    @past_events.reverse!
  end

  def show
    @event = Event.find_by!(slug: params[:id])
  end
end
