class EventsController < ApplicationController
  def index
    @events = Event.published.where('end_time >= ?', Time.current).order(start_time: :asc)
  end

  def show
    @event = Event.find_by!(
      event_name_slug: params[:event_name_slug], 
      event_variation_slug: params[:event_variation_slug]
    )
    
    unless @event.published?
      raise ActionController::RoutingError.new('Not Found')
    end

    tag_name = @event.tags.first&.name
    if tag_name.present?
      @articles = Article.published.cached_tagged_with(tag_name).order(hotness_score: :desc).limit(15)
    else
      @articles = Article.published.order(hotness_score: :desc).limit(15)
    end
  end
end
