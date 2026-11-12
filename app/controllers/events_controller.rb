class EventsController < ApplicationController
  def index
    @events = Event.published.includes(:page).where('end_time >= ?', Time.current).order(start_time: :asc)
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

      if @event.delegate_to_page? && @event.page.present?
        redirect_to @event.page.path
        return
      end

      if @event.challenge?
        render "challenge"
        return
      end

      tag_name = @event.tags.first&.name
      articles = Article.published.includes(:user).order(hotness_score: :desc).limit(15)
      articles = articles.cached_tagged_with(tag_name) if tag_name.present?
      # Load eagerly so the view's `@articles.any?` reuses the loaded records
      # instead of issuing a separate `SELECT 1 ... LIMIT 1` existence query.
      @articles = articles.load
    else
      check_for_page_fallback
    end
  end

  private

  def check_for_page_fallback
    slug = "events/#{params[:event_name_slug]}/#{params[:event_variation_slug]}"
    subforem_pages = Page.from_subforem
    @page = subforem_pages.find_by(slug: slug)
    @page ||= Page.find_by(slug: slug) unless subforem_pages.where_clause.empty?

    if @page && FeatureFlag.accessible?(@page.feature_flag_name, current_user)
      set_surrogate_key_header "show-page-#{@page.slug}"

      if @page.redirect_to_url.present?
        redirect_options = { status: :moved_permanently }
        redirect_options[:allow_other_host] = true if @page.redirect_to_url.start_with?("http://", "https://")
        redirect_to @page.redirect_to_url, **redirect_options
        return
      end

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
