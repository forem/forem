class EventsController < ApplicationController
  SHOW_ARTICLE_COLUMNS = %i[id user_id path title cached_tag_list published_at].freeze
  EVENT_ARTICLE_COLUMNS = %i[
    id user_id path title type_of cached_tag_list published_at
    public_reactions_count comments_count reading_time
  ].freeze
  SHOW_USER_COLUMNS = %i[id name username profile_image].freeze
  EVENT_ARTICLES_LIMIT = 15
  COMMUNITY_ARTICLES_LIMIT = 15
  PAST_LANDING_LIMIT = 12
  SIBLING_SESSIONS_LIMIT = 4
  private_constant :SHOW_ARTICLE_COLUMNS, :EVENT_ARTICLE_COLUMNS, :SHOW_USER_COLUMNS,
                   :EVENT_ARTICLES_LIMIT, :COMMUNITY_ARTICLES_LIMIT, :PAST_LANDING_LIMIT,
                   :SIBLING_SESSIONS_LIMIT

  def index
    @events = Event.published.includes(:page, :organization, :user)
      .where("end_time >= ?", Time.current)
      .order(start_time: :asc)

    if params[:type_of].present? && Event.type_ofs.key?(params[:type_of])
      @active_type_of = params[:type_of]
      @events = @events.where(type_of: @active_type_of).to_a
      preload_parent_context(@events)
    else
      # Hide sub-events that belong to a published parent so the main directory stays hierarchical.
      @events = @events.top_level_published.to_a
    end

    preload_sub_event_summaries(@events)
  end

  def meetups
    render_type_landing(:meetup)
  end

  def conferences
    render_type_landing(:conference)
  end

  def show
    @event = find_event_by_slugs
    return handle_missing_event if @event.nil?

    @include_draft_hierarchy = current_user&.any_admin? || false
    raise ActionController::RoutingError, "Not Found" unless @event.published? || @include_draft_hierarchy

    if params[:page_suffix].blank? && @event.delegate_to_page? && @event.page.present?
      redirect_to @event.page.path
      return
    end

    load_event_pages
    load_event_hierarchy
    load_signed_up_event_ids
    return if render_event_custom_or_showcase_page

    render_native_event_view
  end

  private

  def find_event_by_slugs
    Event.find_by(
      event_name_slug: params[:event_name_slug],
      event_variation_slug: params[:event_variation_slug],
    )
  end

  def handle_missing_event
    raise ActiveRecord::RecordNotFound if params[:page_suffix].present?

    check_for_page_fallback
  end

  def render_native_event_view
    if @event.challenge?
      load_event_tagged_articles
      preload_article_authors(@event_articles)
      render "challenge"
      return
    end

    load_event_articles
    render "gathering" if @event.meetup? || @event.conference?
  end

  def load_event_pages
    @event_pages = @event.ordered_pages.select do |page|
      FeatureFlag.accessible?(page.feature_flag_name, current_user)
    end
    @showcase_page = @event_pages.detect(&:event_showcase?)
    @event_nav_pages = @event_pages.select { |page| page.show_in_navigation? && page != @showcase_page }
  end

  def load_event_hierarchy
    @sub_event_schedule = @event.sub_event_schedule(include_drafts: @include_draft_hierarchy)

    @parent_memberships = @event.parent_event_memberships
      .ordered
      .includes(parent_event: %i[page organization])
      .select { |m| m.parent_event.present? && (@include_draft_hierarchy || m.parent_event.published?) }
    @parent_events = @parent_memberships.map(&:parent_event)

    load_sibling_sessions
  end

  def load_sibling_sessions
    @primary_parent_event = @parent_events.first
    @sibling_memberships = []
    return if @primary_parent_event.nil?

    now = Time.current
    parent_schedule = @primary_parent_event.sub_event_schedule(
      include_drafts: @include_draft_hierarchy,
      at: now,
    )
    candidates = (parent_schedule.live_memberships + parent_schedule.upcoming_memberships)
      .reject { |m| m.child_event_id == @event.id }
    @sibling_memberships = candidates.first(SIBLING_SESSIONS_LIMIT)
  end

  def load_signed_up_event_ids
    @signed_up_event_ids = Set.new
    return if current_user.blank?

    now = Time.current
    target_ids = []
    target_ids << @event.id if @event.end_time > now
    @sub_event_schedule.all_events.each do |sub_event|
      target_ids << sub_event.id if sub_event.end_time > now
    end
    return if target_ids.empty?

    @signed_up_event_ids = current_user.event_signups
      .where(event_id: target_ids.uniq)
      .pluck(:event_id)
      .to_set
  end

  def preload_sub_event_summaries(events)
    @sub_event_summaries = {}
    event_ids = events.map(&:id)
    return if event_ids.empty?

    now = Time.current
    memberships = EventMembership.where(parent_event_id: event_ids)
      .ordered
      .includes(:child_event)
      .to_a

    memberships.group_by(&:parent_event_id).each do |parent_id, list|
      published_children = list.filter_map { |m| m.child_event if m.child_event&.published? }
      next if published_children.empty?

      live_children = published_children.select { |child| child.live?(now) }
      @sub_event_summaries[parent_id] = {
        total_count: published_children.size,
        live_count: live_children.size,
        live_title: live_children.first&.title
      }
    end
  end

  def preload_parent_context(events)
    @parent_events_by_child_id = Hash.new { |h, k| h[k] = [] }
    event_ids = events.map(&:id)
    return if event_ids.empty?

    EventMembership.where(child_event_id: event_ids)
      .ordered
      .includes(:parent_event)
      .to_a
      .each do |membership|
        parent = membership.parent_event
        next unless parent&.published?

        @parent_events_by_child_id[membership.child_event_id] << parent
      end
  end

  def render_event_custom_or_showcase_page
    @event_page = resolve_requested_event_page
    return false unless @event_page

    set_surrogate_key_header @event.record_key, "show-page-#{@event_page.slug}"
    return true if redirect_to_page_target?(@event_page)

    render_page_content(@event_page, "page")
    true
  end

  def resolve_requested_event_page
    if params[:page_suffix].present?
      target_slug = @event.page_slug_for(params[:page_suffix])
      page = @event_pages.detect { |candidate| candidate.slug == target_slug }
      if page.nil? || !FeatureFlag.accessible?(page.feature_flag_name, current_user)
        raise ActiveRecord::RecordNotFound
      end

      return page
    end

    return unless @showcase_page.present? && params[:mode] != "overview"
    return unless FeatureFlag.accessible?(@showcase_page.feature_flag_name, current_user)

    @showcase_page
  end

  def redirect_to_page_target?(page)
    return false if page.redirect_to_url.blank?

    redirect_options = { status: :moved_permanently }
    redirect_options[:allow_other_host] = true if page.redirect_to_url.start_with?("http://", "https://")
    redirect_to page.redirect_to_url, **redirect_options
    true
  end

  def render_page_content(page, default_view)
    case page.template
    when "txt"
      render plain: page.processed_html, content_type: "text/plain"
    when "json"
      render json: page.body_json
    when "css"
      render plain: page.body_css, content_type: "text/css"
    else
      render default_view
    end
  end

  def load_event_tagged_articles
    @event_articles = []
    @event_article_previews = {}
    return unless @event.articles_visible?

    @event_articles = @event.articles.published
      .select(EVENT_ARTICLE_COLUMNS)
      .order(hotness_score: :desc, published_at: :desc)
      .limit(EVENT_ARTICLES_LIMIT)
      .to_a
    @event_article_previews = load_status_previews(@event_articles)
  end

  def load_status_previews(articles)
    status_ids = articles.filter_map { |article| article.id if article.status? }
    return {} if status_ids.empty?

    Article.select(:id, :type_of, :processed_html)
      .where(id: status_ids)
      .each_with_object({}) do |article, previews|
        preview = article.body_preview
        previews[article.id] = preview if preview.present? && preview.length > 10
      end
  end

  def load_event_articles
    load_event_tagged_articles

    @primary_tag = @event.tags.select(:id, :name).first
    @tag_name = @primary_tag&.name
    articles = Article.published.select(SHOW_ARTICLE_COLUMNS)
      .order(hotness_score: :desc)
      .limit(COMMUNITY_ARTICLES_LIMIT)
    articles = articles.cached_tagged_with(@tag_name) if @tag_name.present?
    articles = articles.where.not(id: @event_articles.map(&:id)) if @event_articles.any?
    @articles = articles.to_a
    preload_article_authors(@event_articles + @articles)
  end

  def preload_article_authors(articles)
    return if articles.empty?

    ActiveRecord::Associations::Preloader.new(
      records: articles, associations: :user, scope: User.select(SHOW_USER_COLUMNS),
    ).call
  end

  def render_type_landing(type_of)
    @event_type = type_of.to_s
    now = Time.current
    base_scope = Event.published.public_send(@event_type).includes(:page, :organization, :user)
    @events = base_scope.where("end_time >= ?", now).order(start_time: :asc).to_a
    @past_events = base_scope.where("end_time < ?", now).order(start_time: :desc).limit(PAST_LANDING_LIMIT).to_a
    all_loaded = @events + @past_events
    preload_sub_event_summaries(all_loaded)
    preload_parent_context(all_loaded)
    render :landing
  end

  def check_for_page_fallback
    slug = "events/#{params[:event_name_slug]}/#{params[:event_variation_slug]}"
    subforem_pages = Page.from_subforem
    @page = subforem_pages.find_by(slug: slug)
    @page ||= Page.find_by(slug: slug) unless subforem_pages.where_clause.empty?

    raise ActiveRecord::RecordNotFound unless @page && FeatureFlag.accessible?(@page.feature_flag_name, current_user)

    if @page.event.present? && !(@page.event.published? || current_user&.any_admin?)
      raise ActionController::RoutingError, "Not Found"
    end

    set_surrogate_key_header "show-page-#{@page.slug}"
    return if redirect_to_page_target?(@page)

    render_page_content(@page, "pages/show")
  end
end
