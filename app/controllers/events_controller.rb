class EventsController < ApplicationController
  def index
    @events = Event.published.where('end_time >= ?', Time.current).order(start_time: :asc)
  end

  def show
    @event = Event.find_by(
      event_name_slug: params[:event_name_slug], 
      event_variation_slug: params[:event_variation_slug]
    )
    
    if @event
      unless @event.published?
        raise ActionController::RoutingError.new('Not Found') unless current_user&.any_admin?
      end

      tag_name = @event.tags.first&.name
      if tag_name.present?
        @articles = Article.published.cached_tagged_with(tag_name).order(hotness_score: :desc).limit(15)
      else
        @articles = Article.published.order(hotness_score: :desc).limit(15)
      end
    else
      check_for_page_fallback
    end
  end

  private

  def check_for_page_fallback
    slug = "events/#{params[:event_name_slug]}/#{params[:event_variation_slug]}"
    @page = Page.from_subforem.find_by(slug: slug) || Page.find_by(slug: slug)

    if @page && FeatureFlag.accessible?(@page.feature_flag_name, current_user)
      if @page.redirect_to_url.present?
        redirect_options = { status: :moved_permanently }
        redirect_options[:allow_other_host] = true if @page.redirect_to_url.start_with?("http://", "https://")
        redirect_to @page.redirect_to_url, **redirect_options
        return
      end

      set_surrogate_key_header "show-page-#{@page.slug}"

      case @page.template
      when "txt"
        render plain: @page.processed_html, content_type: "text/plain"
      when "json"
        render json: @page.body_json
      when "css"
        render plain: @page.body_css, content_type: "text/css"
      else
        render "pages/show"
      end
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
