module EventsHelper
  EVENT_TYPE_ACCENTS = {
    "live_stream" => "calendar__accent--live_stream",
    "takeover" => "calendar__accent--takeover",
    "other" => "calendar__accent--other",
    "challenge" => "calendar__accent--challenge",
    "meetup" => "calendar__accent--meetup",
    "conference" => "calendar__accent--conference"
  }.freeze

  EVENT_PILL_CLASSES = {
    "digital" => "event-pill--digital",
    "live stream" => "event-pill--digital",
    "in-person" => "event-pill--in-person",
    "in person" => "event-pill--in-person",
    "challenge" => "event-pill--challenge",
    "takeover" => "event-pill--takeover",
    "meetup" => "event-pill--meetup",
    "conference" => "event-pill--conference"
  }.freeze

  SIDEBAR_CATEGORY_BY_TYPE = {
    "challenge" => :challenges,
    "live_stream" => :livestreams,
    "takeover" => :takeovers,
    "meetup" => :meetups,
    "conference" => :conferences
  }.freeze

  SIDEBAR_HEADING_I18N_KEYS = {
    %i[upcoming challenges] => "views.main.side.events.headings.upcoming_challenges",
    %i[live challenges] => "views.main.side.events.headings.live_challenges",
    %i[live_and_upcoming challenges] => "views.main.side.events.headings.live_and_upcoming_challenges",
    %i[upcoming livestreams] => "views.main.side.events.headings.upcoming_livestreams",
    %i[live livestreams] => "views.main.side.events.headings.live_livestreams",
    %i[live_and_upcoming livestreams] => "views.main.side.events.headings.live_and_upcoming_livestreams",
    %i[upcoming takeovers] => "views.main.side.events.headings.upcoming_takeovers",
    %i[live takeovers] => "views.main.side.events.headings.live_takeovers",
    %i[live_and_upcoming takeovers] => "views.main.side.events.headings.live_and_upcoming_takeovers",
    %i[upcoming meetups] => "views.main.side.events.headings.upcoming_meetups",
    %i[live meetups] => "views.main.side.events.headings.live_meetups",
    %i[live_and_upcoming meetups] => "views.main.side.events.headings.live_and_upcoming_meetups",
    %i[upcoming conferences] => "views.main.side.events.headings.upcoming_conferences",
    %i[live conferences] => "views.main.side.events.headings.live_conferences",
    %i[live_and_upcoming conferences] => "views.main.side.events.headings.live_and_upcoming_conferences",
    %i[upcoming events] => "views.main.side.events.headings.upcoming_events",
    %i[live events] => "views.main.side.events.headings.live_events",
    %i[live_and_upcoming events] => "views.main.side.events.headings.live_and_upcoming_events"
  }.freeze

  SIDEBAR_EVENT_TYPE_I18N_KEYS = {
    "challenge" => "views.main.side.events.types.challenge",
    "live_stream" => "views.main.side.events.types.live_stream",
    "takeover" => "views.main.side.events.types.takeover",
    "meetup" => "views.main.side.events.types.meetup",
    "conference" => "views.main.side.events.types.conference",
    "other" => "views.main.side.events.types.other"
  }.freeze

  def event_link_target(event)
    if event.delegate_to_page? && event.page.present?
      event.page.path
    else
      event_path(event.event_name_slug, event.event_variation_slug)
    end
  end

  def calendar_range_header(range_start, range_end)
    return t("views.calendar.today") if range_start == range_end && range_start == Time.zone.today
    return l(range_start, format: "%a, %b %-d") if range_start == range_end

    if range_start.year == range_end.year && range_start.month == range_end.month
      "#{l(range_start, format: '%b %-d')} – #{l(range_end, format: '%-d')}"
    elsif range_start.year == range_end.year
      "#{l(range_start, format: '%b %-d')} – #{l(range_end, format: '%b %-d')}"
    else
      "#{l(range_start, format: '%b %-d, %Y')} – #{l(range_end, format: '%b %-d, %Y')}"
    end
  end

  def event_type_accent_class(event)
    EVENT_TYPE_ACCENTS.fetch(event.type_of.to_s, "calendar__accent--other")
  end

  def event_pill_class(event)
    EVENT_PILL_CLASSES.fetch(event.format_pill_label.downcase, "event-pill--default")
  end

  def safe_event_url(url)
    value = url.to_s.strip
    return if value.blank?
    return value if value.start_with?("http://", "https://")
    return value if value.start_with?("/") && !value.start_with?("//")

    nil
  end

  def event_has_tabs?(showcase_page, nav_pages)
    showcase_page.present? || nav_pages.present?
  end

  def event_native_tab_label(event, has_showcase:)
    return t("views.events.pages.tabs.overview") unless has_showcase

    case event.type_of
    when "live_stream"
      t("views.events.pages.tabs.live_stream")
    when "challenge"
      t("views.events.pages.tabs.challenge_details")
    else
      t("views.events.pages.tabs.event_details")
    end
  end

  def event_breadcrumb_links(event)
    links = [[t("views.events.gathering.events"), events_path]]
    if event.challenge?
      links << [t("views.events.pages.breadcrumbs.challenges"), "/challenge"]
    elsif event.meetup?
      links << [t("views.events.gathering.meetups"), meetups_path]
    elsif event.conference?
      links << [t("views.events.gathering.conferences"), conferences_path]
    end
    links
  end

  def event_page_suffix(page)
    page.slug.to_s.split("/").last
  end

  # "10 Mar 09:00 – 11:00" for a same-day event; "10 Mar 09:00 – 18 Mar 17:00"
  # for a multi-day event, so the card shows both the start and end.
  def event_datetime_range(event)
    start_at = event.start_time
    end_at = event.end_time
    return start_at.to_fs(:short) if end_at.blank?

    if start_at.to_date == end_at.to_date
      "#{start_at.to_fs(:short)} – #{end_at.strftime('%H:%M')}"
    else
      "#{start_at.to_fs(:short)} – #{end_at.to_fs(:short)}"
    end
  end

  def sidebar_events_heading(events, now: Time.current)
    return t("views.main.side.events.headings.upcoming_events") if events.blank?

    status = sidebar_events_status(events, now)
    category = sidebar_events_category(events)
    key = SIDEBAR_HEADING_I18N_KEYS.fetch([status, category], "views.main.side.events.headings.upcoming_events")
    t(key)
  end

  def sidebar_event_type_label(event)
    key = SIDEBAR_EVENT_TYPE_I18N_KEYS.fetch(event.type_of.to_s, "views.main.side.events.types.other")
    t(key)
  end

  private

  def sidebar_events_status(events, now)
    has_live = events.any? { |event| event.live?(now) }
    has_upcoming = events.any? { |event| !event.live?(now) }

    if has_live && has_upcoming
      :live_and_upcoming
    elsif has_live
      :live
    else
      :upcoming
    end
  end

  def sidebar_events_category(events)
    types = events.map { |event| event.type_of.to_s }.uniq
    return :events unless types.one?

    SIDEBAR_CATEGORY_BY_TYPE.fetch(types.first, :events)
  end
end
