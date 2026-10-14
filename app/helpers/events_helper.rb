module EventsHelper
  EVENT_TYPE_ACCENTS = {
    "live_stream" => "calendar__accent--live_stream",
    "takeover" => "calendar__accent--takeover",
    "other" => "calendar__accent--other",
    "challenge" => "calendar__accent--challenge"
  }.freeze

  SIDEBAR_CATEGORY_BY_TYPE = {
    "challenge" => :challenges,
    "live_stream" => :livestreams,
    "takeover" => :takeovers
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
    %i[upcoming events] => "views.main.side.events.headings.upcoming_events",
    %i[live events] => "views.main.side.events.headings.live_events",
    %i[live_and_upcoming events] => "views.main.side.events.headings.live_and_upcoming_events"
  }.freeze

  SIDEBAR_EVENT_TYPE_I18N_KEYS = {
    "challenge" => "views.main.side.events.types.challenge",
    "live_stream" => "views.main.side.events.types.live_stream",
    "takeover" => "views.main.side.events.types.takeover",
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
