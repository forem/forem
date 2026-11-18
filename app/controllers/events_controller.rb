class EventsController < ApplicationController
  SHOW_ARTICLE_COLUMNS = %i[id user_id path title cached_tag_list published_at].freeze
  SHOW_USER_COLUMNS = %i[id name profile_image].freeze
  PAST_LANDING_LIMIT = 12
  private_constant :SHOW_ARTICLE_COLUMNS, :SHOW_USER_COLUMNS, :PAST_LANDING_LIMIT

  def index
    @events = Event.published.includes(:page, :organization, :user)
      .where("end_time >= ?", Time.current)
      .order(start_time: :asc)
    return unless params[:type_of].present? && Event.type_ofs.key?(params[:type_of])

    @active_type_of = params[:type_of]
    @events = @events.where(type_of: @active_type_of)
  end

  def meetups
    render_type_landing(:meetup)
  end

  def conferences
    render_type_landing(:conference)
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

      @primary_tag = @event.tags.select(:id, :name).first
      @tag_name = @primary_tag&.name
      articles = Article.published.select(SHOW_ARTICLE_COLUMNS).order(hotness_score: :desc).limit(15)
      articles = articles.cached_tagged_with(@tag_name) if @tag_name.present?
      @articles = articles.to_a
      ActiveRecord::Associations::Preloader.new(
        records: @articles, associations: :user, scope: User.select(SHOW_USER_COLUMNS),
      ).call

      render "gathering" if @event.meetup? || @event.conference?
    else
      check_for_page_fallback
    end
  end

  private

  def render_type_landing(type_of)
    @event_type = type_of.to_s
    now = Time.current
    base_scope = Event.published.public_send(@event_type).includes(:page, :organization, :user)
    @events = base_scope.where("end_time >= ?", now).order(start_time: :asc).to_a
    @past_events = base_scope.where("end_time < ?", now).order(start_time: :desc).limit(PAST_LANDING_LIMIT).to_a
    render :landing
  end

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
