class LiveArticlesController < ApplicationController
  # No authorization required for entirely public controller
  before_action :set_cache_control_headers, only: [:index]

  def index
    @event = Event.find_by(live_now: true)
    @article = Article.where(live_now: true).order("featured_number DESC").first
    if @event
      set_surrogate_key_header "live--event_#{@event.id}"
      render json:
        {
          title: @event.title,
          path: @event.location_url,
          tag_list: [],
          user: {
            name: @event.host_name,
            profile_pic: ProfileImage.new(@event).get(width: 50)
          }
        }
    elsif @article
      set_surrogate_key_header "live--article_#{@article.id}"
      render json:
        {
          title: @article.title,
          path: @article.path,
          tag_list: @article.tag_list,
          user: {
            name: @article.user.name,
            profile_pic: ProfileImage.new(@article.user).get(width: 50)
          }
        }
    else
      set_surrogate_key_header "live--nothing"
      render json: {}
    end
  end
end
